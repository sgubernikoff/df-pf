class ImageAttachmentJob < ApplicationJob
    queue_as :default

    def perform(visit_id, image_urls_param)
        visit = Visit.find(visit_id)
        image_urls = Array(image_urls_param).reject { |url| url == "undefined" }
        
        image_urls.each do |json_string|
            attach_image_to_visit(visit, json_string)
        end
    rescue => e
        Rails.logger.error("ImageAttachmentJob failed for visit #{visit_id}: #{e.message}")
    end
    
    private
    
    def attach_image_to_visit(visit, json_string)
        metadata = JSON.parse(json_string)

        puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        puts metadata
        puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        
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
        WatermarkJob.perform_later(filename: metadata['key'], visit_id: visit.id)
        Rails.logger.info("Successfully attached #{metadata['filename']} to visit #{visit.id}")
    rescue JSON::ParserError => e
        Rails.logger.error("JSON Parse Error for #{json_string}: #{e.message}")
    rescue => e
        Rails.logger.error("Failed to attach image: #{e.message}")
    end
end