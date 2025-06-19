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

      # 🖼️ Image processing (add watermark for images only)
      if content_type.start_with?("image")
        image = MiniMagick::Image.open(tempfile.path)

        # Add a simple text watermark (or path to PNG watermark image)
        image.combine_options do |c|
          c.gravity "SouthEast"
          c.draw "text 10,10 'Danielle Frankel'"
          c.fill "white"
          c.pointsize "22"
        end

        image.write(tempfile.path)
      end

      # 📤 Upload to S3
      s3.put_object(
        bucket: ENV["S3_BUCKET_NAME"],
        key: filename,
        body: File.open(tempfile.path),
        content_type: content_type
      )

      # 🧷 Construct public URL
      url = "https://#{ENV['S3_BUCKET_NAME']}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{filename}"
      urls << url
    end

    render json: { urls: urls }
  rescue => e
    render json: { error: e.message }, status: 500
  end
end