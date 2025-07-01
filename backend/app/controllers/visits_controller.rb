require "base64"
require "open-uri"

class VisitsController < ApplicationController
  def index
    @visits = Visit.includes(:dresses).all
    respond_to do |format|
      format.html
      format.json { render json: @visits.to_json(include: :dresses) }
    end
  end

  def show
    @visit = Visit.find(params[:id])
    unless current_user.is_admin || @visit.user_id == current_user.id
      return render json: { error: "Unauthorized", user_id: current_user.id }, status: :unauthorized
    end
    puts "*****************************not attached*****************************"
    if @visit.images.attached?
      puts "*****************************attached*****************************"
      puts @visit
      images_data = @visit.images.map do |image|
        {
          id: image.id,
          filename: image.filename.to_s,
          url: image.url
        }
      end
      
      render json: {
        images: images_data,
        user_id: @visit.user_id,
        price: @visit.price,
        dress_name: @visit.dress_name
      }
    else
      render json: { error: "Images not available yet.", user_id: @visit.user_id }, status: :not_found
    end
  end

  def new
    @visit = Visit.new
  end

  def create
    unless current_user.is_admin
      return render json: { error: "Unauthorized", user_id: current_user.id }, status: :unauthorized
    end

    if visit_params[:user_id].present?
      user = User.find_by(id: visit_params[:user_id])
    else
      customer_name = visit_params[:customer_name]
      customer_email = visit_params[:customer_email]
      password = SecureRandom.urlsafe_base64(16)
      user = User.new(
        name: customer_name,
        email: customer_email,
        password: password,
        password_confirmation: password,
        is_admin: false
      )
      user.send_reset_password_instructions if user.save
    end

    unless user&.persisted?
      puts user.errors.full_messages
      return render json: { error: "User could not be created or found" }, status: :unprocessable_entity
    end

    @visit = Visit.new(visit_params.except(:selected_dress, :customer_name, :customer_email, :image_urls))
    @visit.user = user
    
    puts "=== IMAGE UPLOAD DEBUG ==="
    puts "Raw JSON string: #{visit_params[:image_urls]}"
    puts "String length: #{visit_params[:image_urls]&.length}"

    image_urls = Array(visit_params[:image_urls]).reject { |url| url == "undefined" }
    image_urls.each do |json_string|
      puts "----------------------------------------------------------------------"
  
      begin
      # Parse the JSON string to get the metadata hash
      metadata = JSON.parse(json_string)
      puts "Parsed metadata: #{metadata}"
    
      # Extract the values from the hash
      key = metadata["key"]
      filename = metadata["filename"]
      content_type = metadata["content_type"]
      byte_size = metadata["byte_size"]
      checksum = metadata["checksum"]
    
      puts "Creating blob with:"
      puts "  Key: #{key}"
      puts "  Filename: #{filename}"
      puts "  Content-Type: #{content_type}"
      puts "  Byte Size: #{byte_size}"
      puts "  Checksum: #{checksum}"
    
      # Use create! (not create_before_direct_upload!) with the actual metadata
      blob = ActiveStorage::Blob.create!(
        key: key,
        filename: filename,
        content_type: content_type,
        byte_size: byte_size,
        checksum: checksum,
        service_name: "amazon"
      )
    
      @visit.images.attach(blob)
      puts "✅ Successfully attached #{filename}"
    
    rescue JSON::ParserError => e
      puts "❌ JSON Parse Error: #{e.message}"
      Rails.logger.error("JSON Parse Error for #{json_string}: #{e.message}")
    rescue => e
      puts "❌ Attachment Error: #{e.message}"
      Rails.logger.error("Failed to attach image: #{e.message}")
    end
  
      puts "----------------------------------------------------------------------"
    end

    dress_data = JSON.parse(visit_params[:selected_dress])
    @dress = Dress.new(
      name: dress_data["title"],
      price: dress_data["price"],
      description: dress_data["description"],
      image_urls: dress_data["images"]
    )

    if @visit.save
      @visit.update(dress_id: @dress.id, shopify_dress_id: dress_data["id"], price:dress_data["price"],dress_name:dress_data["title"]) if @dress.save

      respond_to do |format|
        format.html { redirect_to @visit, notice: 'Visit was successfully created.' }
        format.json { render json: @visit, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.json { render json: @visit.errors, status: :unprocessable_entity }
      end
    end
  end

  def resend_email
    unless current_user.is_admin
      return render json: { error: "Unauthorized", user_id: current_user.id }, status: :unauthorized
    end

    @visit = Visit.find_by(id: params[:id])
    respond_to do |format|
      if @visit.nil?
        format.json { render json: { error: "Visit not found" }, status: :not_found }
      elsif !@visit.visit_pdf.attached?
        format.json { render json: { error: "PDF not attached" }, status: :unprocessable_entity }
      else
        begin
          NotificationMailer.job_completion_email(@visit.user, @visit.id, "Contact us for your password").deliver_later
        rescue => e
          Rails.logger.error("Email enqueue failed: #{e.message}")
          format.json { render json: { error: "Failed to queue email" }, status: :internal_server_error }
        end
      end
    end
  end

  def edit
    @visit = Visit.find(params[:id])
  end

  def update
    @visit = Visit.find(params[:id])
    if @visit.update(visit_params)
      respond_to do |format|
        format.html { redirect_to @visit, notice: 'Visit was successfully updated.' }
        format.json { render json: @visit }
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.json { render json: @visit.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @visit = Visit.find(params[:id])
    @visit.destroy
    respond_to do |format|
      format.html { redirect_to visits_url, notice: 'Visit was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def visit_params
    params.require(:visit).permit(
      :user_id,
      :customer_name,
      :customer_email,
      :notes,
      :selected_dress,
      image_urls: []
    )
  end
end