class NotificationMailer < ApplicationMailer
    default from: 'aglgegxg@gmail.com'
    
    def job_completion_email(user, visit_id)
      @user = user
      @visit = Visit.find(visit_id)
      @url = "localhost:5173/visit/#{6}"
      
      mail(
        to: @user.email,
        subject: "Your Visit PDF for #{@visit.user&.name || 'Danielle Frankel'} is Ready"
      )
    end
  end