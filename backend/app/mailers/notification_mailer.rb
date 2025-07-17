class NotificationMailer < ApplicationMailer
  default from: 'aglgegxg@gmail.com'

  OFFICE_ADDRESSES = {
    'NY' => {
      street: '260 West 39th Street',
      floor: 'Floor 14',
      city: 'New York',
      state: 'New York',
      zip: '10018',
      phone: '323.240.2006'
    },
    'LA' => {
      street: '8475 Melrose Place',
      floor: nil,
      city: 'Los Angeles',
      state: 'California',
      zip: '90069',
      phone: '323.533.7241'
    }
  }.freeze

  def job_completion_email
    @user = params[:user]
    @visit = Visit.find(params[:visit_id])
    @url = "localhost:5173/visit/#{@visit.id}"
    # Fix: Parse cc_emails if it's a string
    cc_emails_param = params[:cc_emails] || []
    @cc_emails = case cc_emails_param
              when String
                begin
                  JSON.parse(cc_emails_param)
                rescue JSON::ParserError
                  []
                end
              when Array
                cc_emails_param
              else
                []
              end
    @salesperson = @user.salesperson
    
    # Transform office code to formatted address
    @office_address = format_office_address(@salesperson.office)
    @office_phone = OFFICE_ADDRESSES[@salesperson.office][:phone]
  
    # Attach the logo
    attachments.inline['logo.png'] = File.read(Rails.root.join('app', 'assets', 'images', 'DanielleFrankelMainLogo.jpg'))

    mail(
      to: @user.email,
      cc: @cc_emails,
      subject: "Your PDF for #{@visit.dress.name || 'Danielle Frankel'} is Ready"
    )
  end

  private

  def format_office_address(office_code)
    office = OFFICE_ADDRESSES[office_code]
    return 'Office Address Not Available' unless office

    address_parts = [office[:street]]
    address_parts << office[:floor] if office[:floor]
    first_line = address_parts.join(' | ')
    
    second_line = "#{office[:city]} | #{office[:state]} #{office[:zip]}"
    
    "#{first_line}<br>#{second_line}"
  end
end