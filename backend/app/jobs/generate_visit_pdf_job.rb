class GenerateVisitPdfJob < ApplicationJob
  queue_as :default

  def perform(visit_id)
    visit = Visit.find(visit_id)
    
    if visit.generate_pdf_and_store
      # PDF generation successful, send email notification
      NotificationMailer.job_completion_email(visit.user, visit.id).deliver_now
    else
      # Handle failure case
      Rails.logger.error("Failed to generate PDF for Visit #{visit_id}")
    end
  end
end