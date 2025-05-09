class Visit < ApplicationRecord
  has_many_attached :images
  has_and_belongs_to_many :dresses

  has_one_attached :visit_pdf # This will store the generated PDF

  # Callback to generate PDF after creating the visit
  after_commit :generate_pdf_later, on: :create

  def generate_pdf_later
    GenerateVisitPdfJob.perform_later(self.id)
  end 

  def generate_pdf_and_store
    pdf = Prawn::Document.new
  
    # Add customer name and email
    pdf.text "Customer Name: #{customer_name}"
    pdf.move_down 10
    pdf.text "Customer Email: #{customer_email}"
    pdf.move_down 20
  
    # Layout settings
    image_width = 230
    image_height = 150
    row_gap = 40
    note_gap = 15
    images_per_row = 2
  
    # Calculate spacing
    available_width = pdf.bounds.width
    col_gap = (available_width - (images_per_row * image_width)) / (images_per_row - 1)
    x_positions = Array.new(images_per_row) { |i| pdf.bounds.left + i * (image_width + col_gap) }
  
    images.each_slice(images_per_row) do |row_images|
      # Estimate space needed: image + note + row_gap
      space_needed = image_height + note_gap + row_gap
      if pdf.cursor < space_needed
        pdf.start_new_page
      end
  
      # Draw each image with fixed box (same visual size)
      row_images.each_with_index do |image, col_index|
        image.blob.open do |file|
          x = x_positions[col_index]
          y = pdf.cursor
          pdf.image file.path, at: [x, y], fit: [image_width, image_height]
        end
      end
  
      # Move below image row before drawing notes
      pdf.move_down(image_height + note_gap)
      pdf.text "Notes: #{notes}"
      pdf.move_down(row_gap)
    end
  
    # Store and attach the PDF
    pdf_path = Rails.root.join("tmp", "visits", "visit_#{id}.pdf")
    FileUtils.mkdir_p(File.dirname(pdf_path)) unless File.exist?(File.dirname(pdf_path))
    pdf.render_file(pdf_path)
  
    visit_pdf.attach(
      io: File.open(pdf_path),
      filename: "visit_#{id}.pdf",
      content_type: "application/pdf"
    )
  end  
  
  
end