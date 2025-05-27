require 'open-uri'
require 'vips'
require 'mini_magick'
require 'hexapdf'

class Visit < ApplicationRecord
  has_many_attached :images, dependent: :purge_later
  has_one_attached :visit_pdf, dependent: :purge_later

  belongs_to :dress, optional: true
  belongs_to :user

  validates :user_id, presence: true

  after_commit :generate_pdf_later, on: :create

  def generate_pdf_later
    Rails.logger.info("Generating PDF for Visit #{id}")
    GenerateVisitPdfJob.perform_later(id)
  end

  def convert_heic_to_jpg(tempfile)
    image = MiniMagick::Image.open(tempfile.path)
    image.auto_orient
    image.strip
    image.rotate(90) if image[:width] > image[:height]

    jpg_file = Tempfile.new(['converted', '.jpg'], binmode: true)
    image.format("jpg")
    image.write(jpg_file.path)
    jpg_file
  end

  def generate_pdf_and_store
    Rails.logger.info("Starting PDF generation for Visit #{id}...")

    pdf = Prawn::Document.new
    pdf.font "Helvetica"

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
      page_width = pdf.bounds.width
      image_gap = 10
      image_width = (page_width - image_gap * 2) / 3.0
      top_y = pdf.bounds.height - 20
      image_heights = []

      dress.image_urls.first(3).each_with_index do |url, i|
        begin
          image_file = Tempfile.new(["dress_image_#{i}", ".jpg"])
          image_file.binmode
          image_file.write(URI.open(url).read)
          image_file.rewind

          image = Vips::Image.new_from_file(image_file.path)
          aspect_ratio = image.width.to_f / image.height.to_f
          image_height = image_width / aspect_ratio
          x = i * (image_width + image_gap)

          pdf.image image_file.path, at: [x, top_y], width: image_width, height: image_height
          image_heights << image_height
        rescue => e
          Rails.logger.error("Error processing dress image #{url}: #{e.message}")
        ensure
          image_file.close
          image_file.unlink
        end
      end

      bottom_y = top_y - (image_heights.max || 0) - 10
      pdf.bounding_box([0, bottom_y], width: page_width) do
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

    # Gallery Pages (updated layout)
    if images.attached?
      images_per_row = 3
      gap_x = 10
      gap_y = 20
      image_width = (pdf.bounds.width - (images_per_row - 1) * gap_x) / images_per_row
      image_height = image_width * 1.5

      initial_top_y = pdf.bounds.top - 300  # First page: halfway down
      regular_top_y = pdf.bounds.top - 40
      current_y = initial_top_y

      images.each_slice(images_per_row).with_index do |row_images, page_idx|
        if page_idx > 0
          pdf.start_new_page
          current_y = regular_top_y
        end

        row_images.each_with_index do |image, col|
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
                img.rotate(90) if img[:width] > img[:height]
                jpg = Tempfile.new(['oriented', '.jpg'], binmode: true)
                img.write(jpg.path)
                jpg
              else
                file
              end

              original = Vips::Image.new_from_file(file_to_use.path, access: :sequential)
              watermark_path = Rails.root.join("app/assets/images/watermark2.png")
              next unless File.exist?(watermark_path)

              watermark = Vips::Image.new_from_file(watermark_path.to_s)
              watermark = watermark.resize(original.width.to_f / watermark.width) if watermark.width > original.width
              watermark = watermark.bandjoin(255) unless watermark.has_alpha?
              watermark = watermark * [1, 1, 1, 0.3]
              x_offset = (original.width - watermark.width) / 2
              y_offset = (original.height - watermark.height) / 2
              composed = original.composite2(watermark, :over, x: x_offset, y: y_offset)

              temp_img = Tempfile.new(["gallery", ".jpg"])
              composed.write_to_file(temp_img.path)

              pdf.image temp_img.path, at: [x, current_y], width: image_width, height: image_height
            rescue => e
              Rails.logger.error("Gallery image failed: #{e.message}")
            ensure
              temp_img&.close
              temp_img&.unlink
              file_to_use&.close if file_to_use.is_a?(Tempfile) && file_to_use != file
            end
          end
        end

        current_y -= (image_height + gap_y)

        if current_y - image_height < pdf.bounds.bottom + 50
          pdf.start_new_page
          current_y = regular_top_y
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
end