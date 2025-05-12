require 'open-uri'
require 'mini_magick'

class Visit < ApplicationRecord
  has_many_attached :images, dependent: :purge_later
  belongs_to :dress, optional: true
  belongs_to :user

  validates :user_id, presence: true
  validates :images, presence: true, on: :create

  has_one_attached :visit_pdf, dependent: :purge_later

  after_commit :generate_pdf_later, on: :create

  def generate_pdf_later
    Rails.logger.info("Generating PDF for Visit #{self.id}")
    GenerateVisitPdfJob.perform_later(self.id)
  end

  def generate_pdf_and_store
    Rails.logger.info("Starting PDF generation for Visit #{id}...")

    pdf = Prawn::Document.new
    pdf.font "Helvetica"

    # Cover Page
    pdf.move_down(pdf.bounds.height / 2 - 50)
    image_path = Rails.root.join("public", "images", "DanielleFrankelMainLogo.jpg")
    if File.exist?(image_path)
      Rails.logger.info("Found logo at #{image_path}")
      pdf.image(image_path, width: 200, position: :center)
    else
      Rails.logger.error("Logo file not found at #{image_path}")
    end
    pdf.move_down(15)

    client_name = user.name || "Client"
    Rails.logger.info("Adding client name: #{client_name}")
    pdf.font_size(24) { pdf.text client_name, align: :center, style: :bold }

    # Dress Image Page
    if dress && dress.image_urls.present?
      pdf.start_new_page
      page_width = pdf.bounds.width
      image_gap = 10
      image_width = (page_width - image_gap * 2) / 3
      top_y = pdf.bounds.height - 20
      image_heights = []

      dress.image_urls[0..2].each_with_index do |image_url, i|
        Rails.logger.info("Fetching dress image #{i + 1} from URL: #{image_url}")
        begin
          image_file = Tempfile.new(["dress_image_#{i}", ".jpg"])
          image_file.binmode
          image_data = URI.open(image_url).read
          image_file.write(image_data)
          image_file.rewind

          Rails.logger.info("Dress image tempfile created at #{image_file.path} (#{image_data.bytesize} bytes)")

          image = MiniMagick::Image.open(image_file.path)
          Rails.logger.info("Image format: #{image.type}, width: #{image.width}, height: #{image.height}")

          aspect_ratio = image.width.to_f / image.height.to_f
          image_height = image_width / aspect_ratio
          x = i * (image_width + image_gap)
          y = top_y

          pdf.image image_file.path, at: [x, y], width: image_width, height: image_height
          image_heights << image_height

          image_file.close
          image_file.unlink
        rescue => e
          Rails.logger.error("Error processing dress image at #{image_url}: #{e.class} - #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
        end
      end

      max_image_height = image_heights.max || 0
      bottom_of_images = top_y - max_image_height - 10

      pdf.bounding_box([0, bottom_of_images], width: page_width) do
        pdf.font_size(12) { pdf.text dress.name.to_s, align: :center, style: :bold }
        pdf.move_down 1
        if dress.price.present?
          pdf.font_size(10) { pdf.text "$#{dress.price}", align: :center }
        end
        pdf.move_down 1
        pdf.font_size(10) { pdf.text dress.description.to_s, align: :center }
      end
    else
      Rails.logger.warn("No dress or image URLs available for Visit #{id}")
    end

    # Gallery Pages
    gallery_images = images || []
    notes_added = false

    gallery_images.each_slice(9).with_index do |page_images, idx|
      pdf.start_new_page
      image_width = 160
      image_height = 210
      gap_x = 15
      gap_y = 10

      page_images.each_with_index do |image, index|
        row = index / 3
        col = index % 3
        x = col * (image_width + gap_x)
        y = pdf.bounds.top - row * (image_height + gap_y)

        image.blob.open do |file|
          begin
            Rails.logger.info("Opened gallery image blob: #{file.path}")
            original_img = MiniMagick::Image.open(file.path)
            Rails.logger.info("Gallery image format: #{original_img.type}, dimensions: #{original_img.width}x#{original_img.height}")

            watermark_path = Rails.root.join("app", "assets", "images", "watermark.png")
            unless File.exist?(watermark_path)
              Rails.logger.warn("Watermark image not found at #{watermark_path}")
              next
            end

            Rails.logger.info("Watermark image found at #{watermark_path}")
            watermark = MiniMagick::Image.open(watermark_path)

            # Composite using MiniMagick DSL
            result = original_img.composite(watermark) do |c|
              c.gravity "Center"
              c.compose "Over"
              c.dissolve "30"
            end

            temp_file = Tempfile.new(["gallery_image_#{index}", ".jpg"])
            result.write(temp_file.path)
            Rails.logger.info("Watermarked image written to #{temp_file.path}")

            pdf.bounding_box([x, y], width: image_width, height: image_height) do
              pdf.image temp_file.path, fit: [image_width, image_height], position: :center, vposition: :center
            end

            temp_file.close
            temp_file.unlink
          rescue => e
            Rails.logger.error("Failed to process gallery image #{index + 1} on page #{idx + 1}: #{e.class} - #{e.message}")
            Rails.logger.error(e.backtrace.join("\n"))
          end
        end
      end

      if idx == (gallery_images.size - 1) / 9 && !notes_added
        if pdf.cursor > 100
          pdf.move_down 20
          pdf.font_size(10) { pdf.text "Notes:", style: :bold }
          pdf.move_down 5
          pdf.font_size(8) { pdf.text notes.to_s }
          notes_added = true
        end
      end
    end

    # Notes (Final Page)
    if notes.present? && !notes_added
      pdf.start_new_page
      pdf.move_down 50
      pdf.font_size(10) { pdf.text "Notes:", style: :bold }
      pdf.move_down 10
      pdf.font_size(8) { pdf.text notes.to_s }
    end

    pdf_path = Rails.root.join("tmp", "visits", "visit_#{id}.pdf")
    Rails.logger.info("Saving generated PDF to #{pdf_path}")
    FileUtils.mkdir_p(File.dirname(pdf_path))
    pdf.render_file(pdf_path)

    visit_pdf.attach(
      io: File.open(pdf_path),
      filename: "visit_#{id}.pdf",
      content_type: "application/pdf"
    )

    Rails.logger.info("PDF successfully generated and attached for Visit #{id}")
  rescue => e
    Rails.logger.error("Error during PDF generation for Visit #{id}: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
  end
end
