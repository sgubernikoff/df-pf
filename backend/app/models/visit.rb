def generate_pdf_and_store
  Rails.logger.info("Starting PDF generation for Visit #{id}...")

  pdf = Prawn::Document.new(
    top_margin: 10,
    bottom_margin: 10,
    left_margin: 10,
    right_margin: 10
  )
  pdf.font "Helvetica"

  # Shared uniform image sizing
  uniform_image_width = 140
  uniform_image_gap = 10
  uniform_aspect_ratio = 3.0 / 4.0
  uniform_scaling_factor = 0.93
  uniform_image_height = (uniform_image_width / uniform_aspect_ratio) * uniform_scaling_factor

  # Cover Page
  pdf.move_down(pdf.bounds.height / 2 - 50)
  logo_path = Rails.root.join("public", "images", "DanielleFrankelMainLogo.jpg")
  pdf.image(logo_path, width: 200, position: :center) if File.exist?(logo_path)

  pdf.move_down(15)
  client_name = user.name || "Client"
  pdf.font_size(24) { pdf.text client_name, align: :center, style: :bold }

  # Dress Page
  if dress&.image_urls.present?
    pdf.start_new_page
    top_y = pdf.bounds.top
    image_heights = []

    dress.image_urls.first(3).each_with_index do |url, i|
      begin
        image_file = Tempfile.new(["dress_image_#{i}", ".jpg"])
        image_file.binmode
        image_file.write(URI.open(url).read)
        image_file.rewind

        image = Vips::Image.new_from_file(image_file.path)
        x = i * (uniform_image_width + uniform_image_gap)

        pdf.image image_file.path, at: [x, top_y], width: uniform_image_width, height: uniform_image_height
        image_heights << uniform_image_height
      rescue => e
        Rails.logger.error("Error processing dress image #{url}: #{e.message}")
      ensure
        image_file.close
        image_file.unlink
      end
    end

    bottom_y = top_y - uniform_image_height
    pdf.bounding_box([0, bottom_y - 5], width: pdf.bounds.width) do
      pdf.font_size(12) { pdf.text dress.name.to_s, align: :center, style: :bold }
      pdf.font_size(10) do
        pdf.move_down 1
        price_text = dress.price.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: '')
        pdf.text(price_text, align: :center) if dress.price.present?
        pdf.move_down 1
        pdf.text(dress.description.to_s, align: :center)
      end
    end
  end

  # Gallery Pages
  if images.attached?
    images_per_row = 3
    gap_x = uniform_image_gap
    gap_y = 10
    image_width = uniform_image_width
    image_height = uniform_image_height

    initial_top_y = pdf.cursor - 5
    regular_top_y = pdf.cursor - 5
    current_y = initial_top_y

    images.each_with_index do |image, i|
      col = i % images_per_row
      row = i / images_per_row

      if row > 0 && col == 0 && current_y - image_height < 10
        pdf.start_new_page
        current_y = regular_top_y
      end

      x = col * (image_width + gap_x)

      image.blob.open do |file|
        temp_img = nil
        begin
          ext = File.extname(file.path).downcase
          file_to_use = if ext == ".heic"
            convert_heic_to_jpg(file)
          elsif [".jpg", ".jpeg"].include?(ext)
            img = MiniMagick::Image.open(file.path)
            img.auto_orient
            img.strip

            actual_aspect_ratio = img[:width].to_f / img[:height].to_f
            img.rotate(90) if actual_aspect_ratio > 1.2

            jpg = Tempfile.new(['oriented', '.jpg'], binmode: true)
            img.write(jpg.path)
            jpg
          else
            file
          end

          original = Vips::Image.new_from_file(file_to_use.path, access: :sequential)
          original_aspect_ratio = original.width.to_f / original.height.to_f

          if original_aspect_ratio > (image_width.to_f / image_height)
            display_width = image_width
            display_height = image_width / original_aspect_ratio
          else
            display_height = image_height
            display_width = image_height * original_aspect_ratio
          end

          x_offset = (image_width - display_width) / 2
          y_offset = (image_height - display_height) / 2

          watermark_path = Rails.root.join("app/assets/images/watermark2.png")
          next unless File.exist?(watermark_path)

          watermark = Vips::Image.new_from_file(watermark_path.to_s)
          watermark = watermark.resize(original.width.to_f / watermark.width) if watermark.width > original.width
          watermark = watermark.bandjoin(255) unless watermark.has_alpha?
          watermark = watermark * [1, 1, 1, 0.3]
          composed = original.composite2(watermark, :over, x: (original.width - watermark.width) / 2, y: (original.height - watermark.height) / 2)

          temp_img = Tempfile.new(["gallery", ".jpg"])
          composed.write_to_file(temp_img.path)

          pdf.image temp_img.path,
                    at: [x + x_offset, current_y - y_offset],
                    width: display_width,
                    height: display_height
        rescue => e
          Rails.logger.error("Gallery image failed: #{e.message}")
        ensure
          temp_img&.close
          temp_img&.unlink
          file_to_use&.close if file_to_use.is_a?(Tempfile) && file_to_use != file
        end
      end

      if col == images_per_row - 1 || i == images.size - 1
        current_y -= (image_height + gap_y)
      end
    end
  end

  # Notes Page
  if notes.present?
    pdf.start_new_page
    pdf.font_size(10) { pdf.text "Notes:", style: :bold }
    pdf.move_down 10
    pdf.font_size(8) { pdf.text notes.to_s }
  end

  # Save and Encrypt
  pdf_path = Rails.root.join("tmp", "visits", "visit_#{id}.pdf")
  FileUtils.mkdir_p(File.dirname(pdf_path))
  pdf.render_file(pdf_path)

  password = SecureRandom.hex(4)
  encrypted_path = pdf_path.sub_ext('.encrypted.pdf')
  doc = HexaPDF::Document.open(pdf_path.to_s)
  doc.encrypt(owner_password: 'admin', user_password: password)
  doc.write(encrypted_path.to_s)

  visit_pdf.attach(
    io: File.open(encrypted_path),
    filename: "visit_#{id}.pdf",
    content_type: "application/pdf",
    identify: false
  )

  Rails.logger.info("Encrypted PDF generated for Visit #{id}")
  password
rescue => e
  Rails.logger.error("PDF generation error for Visit #{id}: #{e.class} - #{e.message}")
  false
end