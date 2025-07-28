# This job is responsible for finalizing the watermarking process for a Visit.
class WatermarkFinalizerJob < ApplicationJob
    queue_as :default
  
    def perform(visit_id:,expected_length:,cc_emails:[])
      visit = Visit.find(visit_id)
      return unless visit.all_images_watermarked? && visit.images.length == expected_length
  
      visit.mark_ready!(cc_emails:cc_emails)
    end
  end
  