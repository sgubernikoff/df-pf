class WatermarkJob < ApplicationJob
  queue_as :default

  def perform(filename:, content_type:)
    if content_type.start_with?("image")
      watermark_image(filename, content_type)
    elsif content_type.start_with?("video")
      watermark_video(filename, content_type)
    end
  end

  def watermark_image(filename, content_type)
    s3 = Aws::S3::Client.new(
      region: ENV["AWS_REGION"],
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
    )

    temp_file = Tempfile.new(['original', File.extname(filename)], binmode: true)
    s3.get_object(response_target: temp_file.path, bucket: ENV["S3_BUCKET_NAME"], key: filename)

    original = Vips::Image.new_from_file(temp_file.path, access: :sequential)

    watermark_path = Rails.root.join("app/assets/images/watermark2.png")
    return unless File.exist?(watermark_path)

    watermark = Vips::Image.new_from_file(watermark_path.to_s)
    
    # Resize watermark to match original image dimensions exactly
    watermark = watermark.resize(original.width.to_f / watermark.width)
                        .resize(original.height.to_f / watermark.height)
    
    # Ensure watermark has alpha channel
    watermark = watermark.bandjoin(255) unless watermark.has_alpha?
    
    # Apply opacity (adjust 0.5 to desired transparency level)
    watermark = watermark * [1, 1, 1, 0.5]

    # Composite watermark over entire image (position 0,0 covers full image)
    composed = original.composite2(watermark, :over, x: 0, y: 0)

    # Create output temp file
    output_temp = Tempfile.new(['watermarked', File.extname(filename)], binmode: true)
    composed.write_to_file(output_temp.path)

    # Overwrite the original file in S3
    s3.put_object(
      bucket: ENV["S3_BUCKET_NAME"],
      key: filename,
      body: File.open(output_temp.path),
      content_type: content_type,
      metadata: {
        'watermarked' => 'true',
        'processed_at' => Time.current.iso8601
      }
    )

    # Cleanup
    temp_file.close
    temp_file.unlink
    output_temp.close
    output_temp.unlink
  end

  def watermark_video(filename, content_type)
    s3 = Aws::S3::Client.new(
      region: ENV["AWS_REGION"],
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
    )

    temp_input = Tempfile.new(['input', File.extname(filename)], binmode: true)
    temp_output = Tempfile.new(['output', File.extname(filename)], binmode: true)

    s3.get_object(response_target: temp_input.path, bucket: ENV["S3_BUCKET_NAME"], key: filename)

    watermark_path = Rails.root.join("app/assets/images/video_watermark.png")
    return unless File.exist?(watermark_path)

    # FFmpeg command to scale watermark to full video dimensions and overlay
    ffmpeg_cmd = [
      "ffmpeg",
      "-i", Shellwords.escape(temp_input.path),
      "-i", Shellwords.escape(watermark_path.to_s),
      "-filter_complex",
      "\"[0:v][1:v]overlay=0:0:alpha=0.5\"",
      "-c:a", "copy",
      "-y",
      Shellwords.escape(temp_output.path)
    ].join(" ")

    success = system(ffmpeg_cmd)
    
    if success && File.exist?(temp_output.path) && File.size(temp_output.path) > 0
      # Overwrite the original file in S3
      s3.put_object(
        bucket: ENV["S3_BUCKET_NAME"],
        key: filename,
        body: File.open(temp_output.path),
        content_type: content_type,
        metadata: {
          'watermarked' => 'true',
          'processed_at' => Time.current.iso8601
        }
      )
    else
      Rails.logger.error "FFmpeg failed to process video: #{filename}"
      raise "Video watermarking failed"
    end

    # Cleanup
    temp_input.close
    temp_input.unlink
    temp_output.close
    temp_output.unlink
  end
end