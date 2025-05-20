require "base64"

class VisitsController < ApplicationController
    # GET /visits
    def index
      @visits = Visit.includes(:dresses).all
  
      respond_to do |format|
        format.html # renders index.html.erb if needed
        format.json { render json: @visits.to_json(include: :dresses) }
      end
    end
  
    # GET /visits/:id
    def show
      @visit = Visit.find(params[:id])
    
      unless current_user.is_admin || @visit.user_id == current_user.id
        return render json: { error: "Unauthorized", user_id: current_user.id }, status: :unauthorized
      end
    
      if @visit.visit_pdf.attached?
        base64_pdf = Base64.strict_encode64(@visit.visit_pdf.download)
        render json: {
          pdf_base64: "data:application/pdf;base64,#{base64_pdf}",
          user_id: @visit.user_id
        }
      else
        render json: { error: "PDF not available yet.", user_id: @visit.user_id }, status: :not_found
      end
    end
  
    # GET /visits/new
    def new
      @visit = Visit.new
    end
  
    # POST /visits
    def create
      unless current_user.is_admin
        return render json: { error: "Unauthorized", user_id: current_user.id }, status: :unauthorized
      end
      # Step 1: Handle user association
      if visit_params[:user_id].present?
        user = User.find_by(id: visit_params[:user_id])
      else
        customer_name = visit_params[:customer_name]
        customer_email = visit_params[:customer_email]
        password = SecureRandom.urlsafe_base64(16) # 22 characters, safe for URLs

        # user = User.new(
        #   name: customer_name,
        #   email: customer_email,
        #   password: password,
        #   password_confirmation: password,
        #   is_admin: false
        # )
        # user.send_reset_password_instructions if user.save
        user = User.create(
          name: customer_name,
          email: customer_email,
          password: password,
          password_confirmation: password,
          is_admin: false
        )
      end
    
      unless user&.persisted?
        puts user.errors.full_messages
        return render json: { error: "User could not be created or found" }, status: :unprocessable_entity
      end
    
      # Step 2: Build the Visit (do not save yet)
      @visit = Visit.new(visit_params.except(:selected_dress, :customer_name, :customer_email))
      @visit.user = user
    
      # Step 3: Parse and build Dress object (do not save yet)
      dress_data = JSON.parse(visit_params[:selected_dress])
      @dress = Dress.new(
        name: dress_data["title"],
        price: dress_data["price"],
        description: dress_data["description"],
        image_urls: dress_data["images"]
      )

      # Step 4: Save Visit and then Dress (if visit succeeds)
      if @visit.save
        @visit.update(dress_id: @dress.id,shopify_dress_id: dress_data["id"]) if @dress.save
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
            NotificationMailer.job_completion_email(@visit.user, @visit.id).deliver_later
            format.json { render json: { message: "Email has been queued for delivery" }, status: :accepted }
          rescue => e
            Rails.logger.error("Email enqueue failed: #{e.message}")
            format.json { render json: { error: "Failed to queue email" }, status: :internal_server_error }
          end
        end
      end
    end
      
    
  
    # GET /visits/:id/edit
    def edit
      @visit = Visit.find(params[:id])
    end
  
    # PATCH/PUT /visits/:id
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
  
    # DELETE /visits/:id
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
        images: []
      )
    end
  end
  