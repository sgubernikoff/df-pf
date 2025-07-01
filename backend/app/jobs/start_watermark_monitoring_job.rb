class StartWatermarkMonitoringJob < ApplicationJob
  queue_as :default
  MAX_ATTEMPTS = 30  # 5 minutes total
  WAIT_TIME = 10.seconds
  
  def perform(visit_id, attempt = 1)
    visit = Visit.find(visit_id)
    
    if visit.all_images_watermarked?
      visit.mark_ready!
    elsif attempt < MAX_ATTEMPTS
      StartWatermarkMonitoringJob.set(wait: WAIT_TIME).perform_later(visit_id, attempt + 1)
    else
      # Handle timeout - maybe mark as failed or send alert
      Rails.logger.error "Watermarking timeout for visit #{visit_id}"
    end
  end
end