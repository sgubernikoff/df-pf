class GenerateVisitPdfJob < ApplicationJob
  queue_as :default

  def perform(visit_id)
    visit = Visit.find(visit_id)
    password = visit.generate_pdf_and_store

    if password
      begin
        NotificationMailer.job_completion_email(visit.user, visit.id, password).deliver_later
      rescue Net::ReadTimeout => e
        Rails.logger.warn("Email likely sent, but SMTP response timed out: #{e.message}")
      end
    else
      Rails.logger.error("Failed to generate PDF for Visit #{visit_id}")
    end
  end
end