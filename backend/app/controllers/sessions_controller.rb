class SessionsController < ApplicationController
  skip_before_action :is_logged_in?, only: :create
    def create
      user = User.find_by(username: params[:username])
      if user&.authenticate(params[:password])
        session[:user_id] = user.id
        render json: user, status: :created
      else
        render json: { errors: ["Incorrect username and password"] }, status: :unauthorized
      end
    end
  
    def destroy
      session.delete :user_id
      # session.delete :number
      head :no_content
    end
  
    
  end
