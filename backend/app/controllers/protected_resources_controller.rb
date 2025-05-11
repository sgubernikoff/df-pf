# app/controllers/api/v1/protected_resources_controller.rb
class ProtectedResourcesController < ApplicationController
    before_action :authenticate_user!
  
    def index
      render json: {
        message: "This is a protected resource",
        user: current_user.email
      }
    end
  end