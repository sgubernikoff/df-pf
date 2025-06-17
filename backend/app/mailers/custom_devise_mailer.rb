class CustomDeviseMailer < ApplicationMailer
  default from: 'no-reply@yourdomain.com'
  helper :application
  default template_path: 'devise/mailer' # fallback to Devise views

  def reset_password_instructions(record, token, opts = {})
    @token = token
    @reset_url = "https://df-pf.vercel.app/reset-password?token=#{@token}"
    opts[:subject] = "Set up your password"
    mail(to: record.email, subject: opts[:subject])
  end
end