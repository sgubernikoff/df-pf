# config/initializers/disable_previews.rb
Rails.application.config.after_initialize do
  module DisableSpecificPreviews
    def previewable?
      return false if content_type == "application/pdf"
      return false if video?
      super
    end
  end
   
  ActiveStorage::Blob.prepend(DisableSpecificPreviews)
end