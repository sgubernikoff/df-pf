class NotificationMailer < ApplicationMailer
  default from: 'aglgegxg@gmail.com'

  def job_completion_email
    @user = params[:user]
    @visit = Visit.find(params[:visit_id])
    @url = "localhost:5173/visit/#{@visit.id}"
  
    # Attach the logo
    attachments.inline['logo.png'] = File.read(Rails.root.join('app', 'assets', 'images', 'DanielleFrankelMainLogo.jpg'))

    mail(
      to: @user.email,
      subject: "Your PDF for #{@visit.dress.name || 'Danielle Frankel'} is Ready"
    )
  end
end