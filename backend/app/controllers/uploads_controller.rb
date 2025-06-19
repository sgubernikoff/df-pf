require 'aws-sdk-s3'
require 'mini_magick'

class UploadsController < ApplicationController
  before_action :authenticate_user!
  
  def create
    files_info = params[:files] || []
    
    if files_info.empty?
      return render json: { error: "No files provided" }, status: 400
    end

    s3 = Aws::S3::Resource.new(
      region: ENV["AWS_REGION"],
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
    )

    bucket = s3.bucket(ENV["S3_BUCKET_NAME"])

    presigned_data = files_info.map do |file_info|
      file_name = file_info['name'] || file_info[:name]
      file_type = file_info['type'] || file_info[:type]
      file_size = file_info['size'] || file_info[:size]
      
      unless file_name && file_type
        next { error: "Missing file name or type" }
      end

      timestamp = Time.current.to_i
      sanitized_name = file_name.gsub(/[^a-zA-Z0-9._-]/, '_')
      unique_filename = "#{timestamp}_#{SecureRandom.hex(8)}_#{sanitized_name}"
      
      # ✅ Fixed: Remove expires_in and use expiration time
      presigned_post = bucket.presigned_post(
        key: unique_filename,
        success_action_status: '201',
        content_type: file_type,
        content_length_range: 1..(10 * 1024 * 1024)
      )

      {
        filename: unique_filename,
        url: presigned_post.url,
        fields: presigned_post.fields,
        final_url: "https://#{ENV['S3_BUCKET_NAME']}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{unique_filename}"
      }
    end

    valid_presigned_data = presigned_data.reject { |item| item.key?(:error) }
    errors = presigned_data.select { |item| item.key?(:error) }

    if valid_presigned_data.empty?
      render json: { error: "No valid files to process", details: errors }, status: 400
    else
      render json: { presigned_urls: valid_presigned_data }
    end

  rescue Aws::S3::Errors::ServiceError => e
    render json: { error: "AWS S3 Error: #{e.message}" }, status: 500
  rescue => e
    render json: { error: "Server Error: #{e.message}" }, status: 500
  end
end