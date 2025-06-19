
# app/controllers/watermark_queue_controller.rb
class WatermarkQueueController < ApplicationController
    def create
      filename = params[:filename]
      return render json: { error: "No filename provided" }, status: 400 unless filename
  
      # Queue the watermarking job without blocking
      WatermarkJob.perform_later(filename: filename)
      
      render json: { success: true, message: "Watermarking queued" }
    rescue => e
      render json: { error: e.message }, status: 500
    end
  end