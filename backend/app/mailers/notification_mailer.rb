class NotificationMailer < ApplicationMailer
  default from: 'aglgegxg@gmail.com'

  def job_completion_email
    @user = params[:user]
    @visit = Visit.find(params[:visit_id])
    @password = params[:password] || "No password provided"
    @url = "localhost:5173/visit/#{@visit.id}"
  
    # Attach the logo
    attachments.inline['logo.png'] = File.read(Rails.root.join('app', 'assets', 'images', 'DanielleFrankelMainLogo.jpg'))
  
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