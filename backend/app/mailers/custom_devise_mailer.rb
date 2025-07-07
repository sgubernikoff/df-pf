require Rails.root.join('app/mailers/application_mailer')

class CustomDeviseMailer < ApplicationMailer
  default from: 'sgubernikoff@gmail.com'
  default template_path: 'devise/mailer' # fallback to Devise views

  # Original method for initial user creation
  def reset_password_instructions(record, token, opts = {})
    @token = token
    @reset_url = build_reset_url(token)
    opts[:subject] = "Set up your password"
    attachments.inline['logo.png'] = File.read(Rails.root.join('app', 'assets', 'images', 'DanielleFrankelMainLogo.jpg'))
    mail(to: record.email, subject: opts[:subject])
  end

  # New method for manual password resets
  def manual_reset_password_instructions(record, token, opts = {})
    @token = token
    @reset_url = build_reset_url(token)
    @user = record
    opts[:subject] = "Reset your password"
    attachments.inline['logo.png'] = File.read(Rails.root.join('app', 'assets', 'images', 'DanielleFrankelMainLogo.jpg'))
    mail(to: record.email, subject: opts[:subject])
  end

  private

  def build_reset_url(token)
    base_url = Rails.env.production? ? 'https://df-pf.vercel.app' : 'http://localhost:5173'
    "#{base_url}/reset-password?token=#{token}"
  end
end