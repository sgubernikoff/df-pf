class Api::V1::VisitsController < ApplicationController
    def index
      @visits = Visit.all
      render json: @visits
    end
  end
  