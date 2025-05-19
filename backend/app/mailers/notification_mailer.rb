class NotificationMailer < ApplicationMailer
    default from: 'aglgegxg@gmail.com'
    
    def job_completion_email(user, visit_id)
      @user = user
      @visit = Visit.find(visit_id)
      @url = "localhost:5173/visit/#{8}"

      if @visit.visit_pdf.attached?
        filename = "visit-#{@visit.id}-#{@user.name.parameterize}.pdf"
  
        attachments[filename] = {
          mime_type: 'application/pdf',
          content: @visit.visit_pdf.download
        }
      end
      
      mail(
        to: @user.email,
        subject: "Your Visit PDF for #{@visit.user&.name || 'Danielle Frankel'} is Ready"
      )
    end
  end