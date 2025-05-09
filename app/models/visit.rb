class Visit < ApplicationRecord
  has_many_attached :images
  has_and_belongs_to_many :dresses

  has_one_attached :visit_pdf # This will store the generated PDF

  after_commit :generate_pdf_later, on: :create

  def generate_pdf_later
    GenerateVisitPdfJob.perform_later(self.id)
  end

  def generate_pdf_and_store
    pdf = Prawn::Document.new
    pdf.font "Helvetica"
  
    # -- PAGE 1: COVER PAGE with LOOKBOOK --
    pdf.move_down(pdf.bounds.height / 2 - 50)
    pdf.font_size(32) { pdf.text "LOOKBOOK", align: :center, style: :bold }
  
    # -- PAGE 2: HERO PAGE --
    pdf.start_new_page
  
    page_width = pdf.bounds.width
    page_height = pdf.bounds.height
  
    images_to_show = images[0..2]
    image_gap = 10
    image_width = (page_width - image_gap * 2) / 3
    top_y = page_height - 20
  
    image_height = 0
  
    images_to_show.each_with_index do |image, i|
      image.blob.open do |file|
        img = MiniMagick::Image.open(file.path)
        img.format("jpeg") unless ["jpg", "jpeg", "png", "gif"].include?(img.type.downcase)
        
        # Apply watermark to image only for pages after the 2nd page
        if images.index(image) > 2
          watermark_path = Rails.root.join("app", "assets", "images", "watermark.png")
          if File.exist?(watermark_path)
            watermark = MiniMagick::Image.open(watermark_path)
            # Scale watermark to 100% of image size
            watermark = watermark.resize("#{img.width}x#{img.height}")
            img = img.composite(watermark) do |c|
              c.gravity "Center"
              c.compose "Over"
              c.dissolve 30 # More transparency
            end
          end
        end
        
        # Save the watermarked image to a temporary file
        temp_file = Tempfile.new(["image_#{i}", ".jpg"])
        img.write(temp_file.path)

        aspect_ratio = img.width.to_f / img.height.to_f
        image_height = image_width / aspect_ratio
        x = i * (image_width + image_gap)
        y = top_y

        pdf.image temp_file.path, at: [x, y], width: image_width, height: image_height
        
        temp_file.close
        temp_file.unlink
      end
    end
  
    bottom_of_images = top_y - image_height
  
    pdf.bounding_box([0, bottom_of_images - 10], width: page_width) do
      pdf.font_size(10) { pdf.text "Demi", align: :center }
      pdf.font_size(8) do
        pdf.text "$2,990 MSRP", align: :center
        pdf.text "Pearl", align: :center
        pdf.text "Sizing US 0 - 24", align: :center
        pdf.move_down 4
        pdf.text "Lace and piped cotton twill basque waisted bodice.", align: :center
      end
    end
  
    # -- PAGE 3+: GALLERY PAGES --
    gallery_images = images[3..] || []
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
          
          # Apply watermark to image
          watermark_path = Rails.root.join("app", "assets", "images", "watermark.png")
          if File.exist?(watermark_path)
            watermark = MiniMagick::Image.open(watermark_path)
            # Scale watermark to 100% of image size
            watermark = watermark.resize("#{img.width}x#{img.height}")
            img = img.composite(watermark) do |c|
              c.gravity "Center"
              c.compose "Over"
              c.dissolve 30 # More transparency
            end
          end

          # Save the watermarked image to a temporary file
          temp_file = Tempfile.new(["image_#{index}", ".jpg"])
          img.write(temp_file.path)

          pdf.bounding_box([x, y], width: image_width, height: image_height) do
            pdf.image temp_file.path, fit: [image_width, image_height], position: :center, vposition: :center
          end

          temp_file.close
          temp_file.unlink
        end
      end

      if idx == (gallery_images.size - 1) / 9 && !notes_added
        remaining_space = pdf.cursor
        if remaining_space > 100
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
