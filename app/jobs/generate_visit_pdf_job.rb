class GenerateVisitPdfJob < ApplicationJob
  queue_as :default

  def perform(visit_id)
    visit = Visit.find(visit_id)
    visit.generate_pdf_and_store
  end
end

