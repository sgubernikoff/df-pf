class NotificationMailer < ApplicationMailer
    default from: 'aglgegxg@gmail.com'
    
    def job_completion_email(user, visit_id)
      @user = user
      @visit = Visit.find(visit_id)
      @url = "localhost:5173/visit/#{8}"

      if @visit.visit_pdf.attached?
        filename = "#{@visit.dress.name}-#{@user.name.parameterize}-#{@visit.created_at.to_date}.pdf"
  
        attachments[filename] = {
          mime_type: 'application/pdf',
          content: @visit.visit_pdf.download
        }
      end
      
      mail(
        to: @user.email,
        subject: "Your PDF for #{@visit.dress.name || 'Danielle Frankel'} is Ready"
      )
    end
  end