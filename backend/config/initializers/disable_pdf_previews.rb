# config/initializers/disable_pdf_previews.rb
Rails.application.config.after_initialize do
  module DisablePDFPreviews
    def previewable?
      return false if content_type == "application/pdf"
      super
    end
  end

  ActiveStorage::Blob.prepend(DisablePDFPreviews)
end