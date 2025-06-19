require 'aws-sdk-s3'
require 'mini_magick'

class UploadsController < ApplicationController
  skip_before_action :authenticate_user! # or whatever auth method you use

  def create
    uploaded_files = params[:files]
    return render json: { error: "No files uploaded" }, status: 400 unless uploaded_files

    s3 = Aws::S3::Client.new(
      region: ENV["AWS_REGION"],
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
    )

    urls = []

    Array(uploaded_files).each do |uploaded_file|
      tempfile = uploaded_file.tempfile
      content_type = uploaded_file.content_type
      filename = uploaded_file.original_filename

      # Upload raw file to S3 immediately
      s3.put_object(
        bucket: ENV["S3_BUCKET_NAME"],
        key: filename,
        body: File.open(tempfile.path),
        content_type: content_type
      )

      # Enqueue background job for watermarking
      WatermarkJob.perform_later(filename: filename, content_type: content_type)

      url = "https://#{ENV['S3_BUCKET_NAME']}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{filename}"
      urls << url
    end

    render json: { urls: urls }
  rescue => e
    render json: { error: e.message }, status: 500
  end
end