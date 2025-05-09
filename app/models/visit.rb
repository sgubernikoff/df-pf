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
  
    # Add visit information to the PDF
    pdf.text "Customer Name: #{customer_name}"
    pdf.text "Customer Email: #{customer_email}"
    pdf.text "Notes: #{notes}"
  
    # Add images if any
    images.each_with_index do |image, index|
      image.blob.open do |file|
        pdf.image file.path, at: [100, 700 - (index * 150)], width: 200
      end
    end
  
    # Store the generated PDF in a file
    pdf_path = Rails.root.join("tmp", "visits", "visit_#{id}.pdf")
    FileUtils.mkdir_p(File.dirname(pdf_path)) unless File.exist?(File.dirname(pdf_path))
    pdf.render_file(pdf_path)
  
    # Attach the generated PDF to the visit record
    visit_pdf.attach(
      io: File.open(pdf_path),
      filename: "visit_#{id}.pdf",
      content_type: "application/pdf"
    )
  end
  
end