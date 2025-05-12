# Preview all emails at http://localhost:3000/rails/mailers/notification_mailer
class NotificationMailerPreview < ActionMailer::Preview
    def job_completion_email
        user = User.first
        visit = Visit.first
        NotificationMailer.job_completion_email(user, visit.id)
    end
end
