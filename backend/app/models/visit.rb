require 'open-uri'
require 'mini_magick'

class Visit < ApplicationRecord
  has_many_attached :images, dependent: :purge_later
  belongs_to :dress, optional: true
  belongs_to :user

  validates :user_id, presence: true
  validates :images, presence: true

  has_one_attached :visit_pdf, dependent: :purge_later

  after_commit :generate_pdf_later, on: :create

  def generate_pdf_later
    GenerateVisitPdfJob.perform_later(self.id)
  end

  def generate_pdf_and_store
    pdf = Prawn::Document.new
    pdf.font "Helvetica"

    # -- PAGE 1: COVER PAGE with CLIENT NAME --
    pdf.move_down(pdf.bounds.height / 2 - 50)
    image_path = Rails.root.join("public", "images", "DanielleFrankelMainLogo.jpg")
    pdf.image(image_path, width: 200, position: :center) if File.exist?(image_path)
    pdf.move_down(15)

    client_name = user.name || "Client"
    pdf.font_size(24) { pdf.text client_name, align: :center, style: :bold }

    # -- PAGE 2: HERO PAGE (Dress Images from Shopify) --
    if dress && dress.image_urls.present?
      pdf.start_new_page
      page_width = pdf.bounds.width
      image_gap = 10
      image_width = (page_width - image_gap * 2) / 3
      top_y = pdf.bounds.height - 20

      images_to_show = dress.image_urls[0..2]

      image_heights = []

      images_to_show.each_with_index do |image_url, i|
        begin
          image_file = Tempfile.new(["dress_image_#{i}", ".jpg"])
          image_file.binmode
          image_file.write(URI.open(image_url).read)
          image_file.rewind

          image = MiniMagick::Image.read(image_file)
          aspect_ratio = image.width.to_f / image.height.to_f
          image_height = image_width / aspect_ratio
          x = i * (image_width + image_gap)
          y = top_y

          pdf.image image_file.path, at: [x, y], width: image_width, height: image_height
          image_heights << image_height

          image_file.close
          image_file.unlink
        rescue => e
          Rails.logger.error("Error processing image at #{image_url}: #{e.message}")
        end
      end

      # Calculate lowest point reached by the tallest image
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
    end

    # -- PAGE 3+: GALLERY PAGES (Uploaded Images with Watermarks) --
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
          img = MiniMagick::Image.open(file.path)
          img.format("jpeg") unless ["jpg", "jpeg", "png", "gif"].include?(img.type.downcase)

          watermark_path = Rails.root.join("app", "assets", "images", "watermark.png")
          if File.exist?(watermark_path)
            watermark = MiniMagick::Image.open(watermark_path)
            watermark = watermark.resize("#{img.width}x#{img.height}")
            img = img.composite(watermark) do |c|
              c.gravity "Center"
              c.compose "Over"
              c.dissolve 30
            end
          end

          temp_file = Tempfile.new(["gallery_image_#{index}", ".jpg"])
          img.write(temp_file.path)

          pdf.bounding_box([x, y], width: image_width, height: image_height) do
            pdf.image temp_file.path, fit: [image_width, image_height], position: :center, vposition: :center
          end

          temp_file.close
          temp_file.unlink
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

    if notes.present? && !notes_added
      pdf.start_new_page
      pdf.move_down 50
      pdf.font_size(10) { pdf.text "Notes:", style: :bold }
      pdf.move_down 10
      pdf.font_size(8) { pdf.text notes.to_s }
    end

    pdf_path = Rails.root.join("tmp", "visits", "visit_#{id}.pdf")
    FileUtils.mkdir_p(File.dirname(pdf_path))
    pdf.render_file(pdf_path)

    visit_pdf.attach(
      io: File.open(pdf_path),
      filename: "visit_#{id}.pdf",
      content_type: "application/pdf"
    )
  end
end
