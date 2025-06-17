class Users::PasswordsController < Devise::PasswordsController
  skip_before_action :authenticate_user!, only: [:update]
  respond_to :json

  def update
    self.resource = resource_class.reset_password_by_token(resource_params)
    if resource.errors.empty?
      render json: { message: "Password updated successfully" }, status: :ok
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end
end