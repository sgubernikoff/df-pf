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
    pdf = Prawn::Document.new
    pdf.font "Helvetica"

    # Cover Page
    pdf.move_down(pdf.bounds.height / 2 - 50)
    logo_path = Rails.root.join("public", "images", "DanielleFrankelMainLogo.jpg")
    pdf.image(logo_path, width: 200, position: :center) if File.exist?(logo_path)

    pdf.move_down(15)
    pdf.font_size(24) { pdf.text(user.name || "Client", align: :center, style: :bold) }

    # Dress Page
    if dress&.image_urls.present?
      pdf.start_new_page
      image_width = 150
      image_height = 225 # Consistent size (iPhone-like)
      gap_x = 15
      top_y = pdf.cursor

      dress.image_urls.first(3).each_with_index do |url, i|
        begin
          img_file = Tempfile.new(["dress_#{i}", ".jpg"])
          img_file.binmode
          img_file.write URI.open(url).read
          img_file.rewind

          x = i * (image_width + gap_x)
          pdf.image img_file.path, at: [x, top_y], width: image_width, height: image_height
        rescue => e
          Rails.logger.error("Dress image error: #{e.message}")
        ensure
          img_file.close
          img_file.unlink
        end
      end

      pdf.move_down(image_height + 30)
      pdf.font_size(12) { pdf.text dress.name.to_s, align: :center, style: :bold }
      pdf.font_size(10) do
        price_text = dress.price.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: '')
        pdf.text(price_text, align: :center) if dress.price.present?
        pdf.move_down 1
        pdf.text(dress.description.to_s, align: :center)
      end

      pdf.move_down(40)
    end

    # Gallery Grid
    if images.attached?
      image_width = 150
      image_height = 225
      gap_x = 15
      gap_y = 30

      images.each_with_index do |img, idx|
        col = idx % 3
        row = idx / 3

        # Start new page if not enough space for another row
        available_space = pdf.cursor - image_height
        pdf.start_new_page if available_space < gap_y + 20

        x = col * (image_width + gap_x)
        y = pdf.cursor

        img.blob.open do |file|
          temp_img = nil
          begin
            ext = File.extname(file.path).downcase
            file_to_use = if ext == ".heic"
              convert_heic_to_jpg(file)
            else
              image = MiniMagick::Image.open(file.path)
              image.auto_orient
              image.strip
              image.rotate(90) if image[:width] > image[:height]
              jpg_file = Tempfile.new(['oriented', '.jpg'], binmode: true)
              image.write(jpg_file.path)
              jpg_file
            end

            original = Vips::Image.new_from_file(file_to_use.path)
            watermark_path = Rails.root.join("app/assets/images/watermark2.png")
            next unless File.exist?(watermark_path)

            watermark = Vips::Image.new_from_file(watermark_path.to_s)
            watermark = watermark.resize(original.width.to_f / watermark.width) if watermark.width > original.width
            watermark = watermark.bandjoin(255) unless watermark.has_alpha?
            watermark = watermark * [1, 1, 1, 0.3]
            composed = original.composite2(watermark, :over,
              x: (original.width - watermark.width) / 2,
              y: (original.height - watermark.height) / 2
            )

            temp_img = Tempfile.new(["img_#{idx}", ".jpg"])
            composed.write_to_file(temp_img.path)

            pdf.bounding_box([x, y], width: image_width, height: image_height) do
              pdf.image temp_img.path, fit: [image_width, image_height]
            end
          rescue => e
            Rails.logger.error("Image #{idx + 1} failed: #{e.message}")
          ensure
            temp_img&.close
            temp_img&.unlink
            file_to_use&.close if file_to_use.is_a?(Tempfile) && file_to_use != file
          end
        end

        pdf.move_down(image_height + gap_y) if col == 2
      end
    end

    # Notes
    if notes.present?
      pdf.start_new_page
      pdf.font_size(10) { pdf.text "Notes:", style: :bold }
      pdf.move_down 10
      pdf.font_size(8) { pdf.text notes.to_s }
    end

    # Save & Encrypt
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

    Rails.logger.info("PDF done for Visit #{id}")
    password
  rescue => e
    Rails.logger.error("PDF generation error: #{e.class} - #{e.message}")
    false
  end
end