class Users::PasswordsController < Devise::PasswordsController
  skip_before_action :authenticate_user!, only: [:update]
  respond_to :json

  # POST /users/password - Send reset password email
  def create
    # Find the user by email
    self.resource = resource_class.find_by(email: resource_params[:email])
    
    if resource
      # Generate reset token manually
      raw_token, hashed_token = Devise.token_generator.generate(resource_class, :reset_password_token)
      
      # Set the token and timestamp
      resource.reset_password_token = hashed_token
      resource.reset_password_sent_at = Time.current
      resource.save(validate: false)
      
      # Send custom email
      CustomDeviseMailer.manual_reset_password_instructions(resource, raw_token).deliver_now
      
      render json: {
        success: true,
        message: "If that email address is in our database, we will send you a password reset link."
      }, status: :ok
    else
      # Always return success to prevent email enumeration
      render json: {
        success: true,
        message: "If that email address is in our database, we will send you a password reset link."
      }, status: :ok
    end
  end

  def update
    self.resource = resource_class.reset_password_by_token(resource_params)
    if resource.errors.empty?
      render json: { message: "Password updated successfully",user: self.resource }, status: :ok
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def resource_params
    params.require(:user).permit(:reset_password_token, :password, :password_confirmation, :email)
  end
end