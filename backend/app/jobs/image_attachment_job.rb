class ImageAttachmentJob < ApplicationJob
    queue_as :default

    def perform(visit_id, image_urls_param,cc_emails:[])
        visit = Visit.find(visit_id)
        image_urls = Array(image_urls_param).reject { |url| url == "undefined" }
        
        image_urls.each_with_index do |json_string, index|
            is_last = (index == image_urls.length - 1)
            attach_image_to_visit(visit, json_string, is_last,cc_emails: cc_emails)
          end
    rescue => e
        Rails.logger.error("ImageAttachmentJob failed for visit #{visit_id}: #{e.message}")
    end
    
    private
    
    def attach_image_to_visit(visit, json_string,is_last,cc_emails:[])
        metadata = JSON.parse(json_string)

        blob = ActiveStorage::Blob.create!(
            key: metadata["key"],
            filename: metadata["filename"],
            content_type: metadata["content_type"],
            byte_size: metadata["byte_size"],
            checksum: metadata["checksum"],
            service_name: "amazon"
        )
        
        # Mark as analyzed by updating metadata - this prevents automatic analysis
        blob.update!(metadata: { analyzed: true, identified: true })
        
        visit.images.attach(blob)

        WatermarkJob.perform_later(filename: metadata['key'], visit_id: visit.id,is_last:is_last,cc_emails:cc_emails || [])
        Rails.logger.info("Successfully attached #{metadata['filename']} to visit #{visit.id}")
    rescue JSON::ParserError => e
        Rails.logger.error("JSON Parse Error for #{json_string}: #{e.message}")
    rescue => e
        Rails.logger.error("Failed to attach image: #{e.message}")
    end
end