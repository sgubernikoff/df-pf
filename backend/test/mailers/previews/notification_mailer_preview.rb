# Preview all emails at http://localhost:3000/rails/mailers/notification_mailer
class NotificationMailerPreview < ActionMailer::Preview
    def job_completion_email
      user = User.first
      visit = Visit.first
  
      NotificationMailer.with(
        user: user,
        visit_id: visit.id,
        password: "sample_password_123"
      ).job_completion_email
    end
  end
