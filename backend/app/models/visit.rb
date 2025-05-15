require 'open-uri'
require 'vips'

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
          pdf.text("#{dress.price}", align: :center) if dress.price.present?
          pdf.move_down 1
          pdf.text(dress.description.to_s, align: :center)
        end
      end
    else
      Rails.logger.warn("No dress or dress image URLs for Visit #{id}")
    end

    # Gallery Pages
    notes_added = false
    image_width = 160
    image_height = 210
    gap_x = 15
    gap_y = 10

    images.each_slice(9).with_index do |batch, idx|
      if pdf.cursor < image_height + gap_y
        pdf.start_new_page
      end
      batch.each_with_index do |image, i|
        row, col = i.divmod(3)
        x = col * (image_width + gap_x)
        y = pdf.bounds.top - row * (image_height + gap_y)

        image.blob.open do |file|
          begin
            Rails.logger.info("Processing gallery image #{i + 1} on page #{idx + 1}")
            original = Vips::Image.new_from_file(file.path, access: :sequential)

            watermark_path = Rails.root.join("app/assets/images/watermark.png")
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

            pdf.bounding_box([x, y], width: image_width, height: image_height) do
              pdf.image temp_img.path, fit: [image_width, image_height], position: :center, vposition: :center
            end
          rescue => e
            Rails.logger.error("Failed gallery image #{i + 1} on page #{idx + 1}: #{e.message}")
          ensure
            temp_img&.close
            temp_img&.unlink
          end
        end
      end

      # Notes at end of last gallery page
      if idx == (images.count - 1) / 9 && notes.present? && !notes_added
        if pdf.cursor > 100
          pdf.move_down 20
          pdf.font_size(10) { pdf.text "Notes:", style: :bold }
          pdf.move_down 5
          pdf.font_size(8) { pdf.text notes.to_s }
          notes_added = true
        end
      end
    end

    # Notes page (if not already added)
    if notes.present? && !notes_added
      pdf.start_new_page
      pdf.move_down 50
      pdf.font_size(10) { pdf.text "Notes:", style: :bold }
      pdf.move_down 10
      pdf.font_size(8) { pdf.text notes.to_s }
    end

    # Save and attach
    pdf_path = Rails.root.join("tmp", "visits", "visit_#{id}.pdf")
    FileUtils.mkdir_p(File.dirname(pdf_path))
    pdf.render_file(pdf_path)

    visit_pdf.attach(
      io: File.open(pdf_path),
      filename: "visit_#{id}.pdf",
      content_type: "application/pdf"
    )

    Rails.logger.info("PDF successfully generated and attached for Visit #{id}")
    
    return true if visit_pdf.attached?
  rescue => e
    Rails.logger.error("Error generating PDF for Visit #{id}: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    
    return false
  end
end
