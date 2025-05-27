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
  validates :images, presence: true, on: :create

  after_commit :generate_pdf_later, on: :create

  def generate_pdf_later
    Rails.logger.info("Generating PDF for Visit #{id}")
    GenerateVisitPdfJob.perform_later(id)
  end

  def convert_heic_to_jpg(tempfile)
    image = MiniMagick::Image.open(tempfile.path)
    image.auto_orient
    image.strip

    if image[:width] > image[:height]
      Rails.logger.info("Rotating landscape image to portrait")
      image.rotate(90)
    end

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

    if File.exist?(logo_path)
      Rails.logger.info("Found logo at #{logo_path}")
      pdf.image(logo_path, width: 200, position: :center)
    else
      Rails.logger.error("Logo file not found at #{logo_path}")
    end

    pdf.move_down(15)
    client_name = user.name || "Client"
    Rails.logger.info("Adding client name: #{client_name}")
    pdf.font_size(24) { pdf.text client_name, align: :center, style: :bold }

    # Dress Page
    if dress&.image_urls.present?
      pdf.start_new_page
      page_width = pdf.bounds.width
      image_gap = 10
      image_width = (page_width - image_gap * 2) / 3
      top_y = pdf.bounds.height - 20
      image_heights = []

      dress.image_urls.first(3).each_with_index do |url, i|
        begin
          Rails.logger.info("Fetching dress image #{i + 1} from URL: #{url}")
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

      bottom_of_images = top_y - (image_heights.max || 0) - 10
      pdf.bounding_box([0, bottom_of_images], width: page_width) do
        pdf.font_size(12) { pdf.text dress.name.to_s, align: :center, style: :bold }
        pdf.font_size(10) do
          pdf.move_down 1
          Rails.logger.info("PRICE VALUE: #{dress.price.inspect}")
          price_text = dress.price.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: '')
          pdf.text(price_text, align: :center) if dress.price.present?
          pdf.move_down 1
          pdf.text(dress.description.to_s, align: :center)
        end
      end

      pdf.move_down(30)
    else
      Rails.logger.warn("No dress or dress image URLs for Visit #{id}")
    end

    # Gallery Pages
    gap_x = 10
    gap_y = 5
    page_width = pdf.bounds.width
    image_width = (page_width - gap_x * 2) / 3.0
    gallery_top_y = pdf.cursor - 100

    images.each_slice(9).with_index do |batch, idx|
      top_y = (idx == 0) ? gallery_top_y : pdf.bounds.top - 20

      batch.each_with_index do |image, i|
        row, col = i.divmod(3)
        x = col * (image_width + gap_x)
        y = top_y - row * ((image_width * 2) + gap_y)

        image.blob.open do |file|
          temp_img = nil
          begin
            Rails.logger.info("Processing gallery image #{i + 1} on page #{idx + 1}")

            ext = File.extname(file.path).downcase
            file_to_use = if ext == ".heic"
              Rails.logger.info("Converting HEIC to JPEG")
              convert_heic_to_jpg(file)
            elsif ext == ".jpg" || ext == ".jpeg"
              Rails.logger.info("Processing JPEG for auto-orient and portrait")
              image = MiniMagick::Image.open(file.path)
              image.auto_orient
              image.strip
              image.rotate(90) if image[:width] > image[:height]
              jpg_file = Tempfile.new(['oriented', '.jpg'], binmode: true)
              image.write(jpg_file.path)
              jpg_file
            else
              file
            end

            original = Vips::Image.new_from_file(file_to_use.path, access: :sequential)

            watermark_path = Rails.root.join("app/assets/images/watermark2.png")
            unless File.exist?(watermark_path)
              Rails.logger.warn("Watermark not found at #{watermark_path}")
              next
            end

            watermark = Vips::Image.new_from_file(watermark_path.to_s, access: :sequential)
            watermark = watermark.resize(original.width.to_f / watermark.width) if watermark.width > original.width
            watermark = watermark.bandjoin(255) unless watermark.has_alpha?
            watermark = watermark * [1, 1, 1, 0.3]

            x_offset = (original.width - watermark.width) / 2
            y_offset = (original.height - watermark.height) / 2
            composed = original.composite2(watermark, :over, x: x_offset, y: y_offset)

            temp_img = Tempfile.new(["gallery_#{i}", ".jpg"])
            composed.write_to_file(temp_img.path)

            pdf.bounding_box([x, y], width: image_width) do
              pdf.image temp_img.path, fit: [image_width, image_width * 2], position: :center, vposition: :center
            end
          rescue => e
            Rails.logger.error("Failed gallery image #{i + 1} on page #{idx + 1}: #{e.message}")
          ensure
            temp_img&.close
            temp_img&.unlink
            file_to_use&.close if file_to_use.is_a?(Tempfile) && file_to_use != file
          end
        end
      end
    end

    # Notes Page (only once)
    if notes.present?
      pdf.start_new_page
      top_padding = pdf.bounds.top - 20 # Adjusted padding to make it start higher
      pdf.bounding_box([0, top_padding], width: pdf.bounds.width) do
        pdf.font_size(10) { pdf.text "Notes:", style: :bold }
        pdf.move_down 10
        pdf.font_size(8) { pdf.text notes.to_s }
      end
    end

    # Save and Encrypt
    pdf_path = Rails.root.join("tmp", "visits", "visit_#{id}.pdf")
    FileUtils.mkdir_p(File.dirname(pdf_path))
    pdf.render_file(pdf_path)

    password = SecureRandom.hex(4)
    encrypted_path = pdf_path.sub_ext('.encrypted.pdf')
    doc = HexaPDF::Document.open(pdf_path.to_s)

    doc.encrypt(
      owner_password: 'admin',
      user_password: password
    )
    doc.write(encrypted_path.to_s)

    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(encrypted_path),
      filename: "visit_#{id}.pdf",
      content_type: "application/pdf",
      identify: false
    )

    visit_pdf.attach(blob)

    Rails.logger.info("Encrypted PDF successfully generated and attached for Visit #{id}")
    return password if visit_pdf.attached?
  rescue => e
    Rails.logger.error("Error generating PDF for Visit #{id}: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    return false
  end
end