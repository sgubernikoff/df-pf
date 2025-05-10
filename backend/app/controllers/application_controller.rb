class ApplicationController < ActionController::API
    include ActionController::Cookies
    before_action :is_logged_in?
  
    def is_logged_in?
      render json: {errors: ['UNAUTHORIZED: PLEASE LOGIN.']}, status: :unauthorized unless session.include? :user_id
    end
  end