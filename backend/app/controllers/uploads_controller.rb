require 'aws-sdk-s3'

class UploadsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    file = params[:file]
    return render json: { error: "No file uploaded" }, status: 400 unless file

    s3 = Aws::S3::Client.new(
      region: ENV["AWS_REGION"],
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
    )

    key = file.original_filename

    begin
      s3.put_object(
        bucket: ENV["S3_BUCKET_NAME"],
        key: key,
        body: file.tempfile,
        content_type: file.content_type
      )

      public_url = "https://#{ENV['S3_BUCKET_NAME']}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{key}"
      render json: { url: public_url }
    rescue Aws::S3::Errors::ServiceError => e
      render json: { error: e.message }, status: 500
    end
  end
end