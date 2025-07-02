require 'securerandom'
class WatermarkJob < ApplicationJob
  queue_as :default

  def perform(filename:, content_type: nil)
    # Get content_type from S3 if not provided
    content_type ||= get_content_type_from_s3(filename)
    
    # Check if already watermarked to avoid reprocessing
    return if already_watermarked?(filename)

    if content_type&.start_with?("image")
      watermark_image(filename, content_type)
    elsif content_type&.start_with?("video")
      watermark_video(filename, content_type)
    else
      Rails.logger.warn "Unsupported content type for watermarking: #{content_type}"
    end
  rescue => e
    Rails.logger.error "Watermarking failed for #{filename}: #{e.message}"
    # Optionally notify error tracking service
    # Sentry.capture_exception(e) if defined?(Sentry)
    raise e # Re-raise to trigger job retry
  end

  private

  def s3_client
    @s3_client ||= Aws::S3::Client.new(
      region: ENV["AWS_REGION"],
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
    )
  end

  def get_content_type_from_s3(filename)
    response = s3_client.head_object(bucket: ENV["S3_BUCKET_NAME"], key: filename)
    response.content_type
  rescue Aws::S3::Errors::NotFound
    Rails.logger.error "File not found in S3: #{filename}"
    nil
  end

  def already_watermarked?(filename)
    response = s3_client.head_object(bucket: ENV["S3_BUCKET_NAME"], key: filename)
    response.metadata['watermarked'] == 'true'
  rescue Aws::S3::Errors::NotFound
    false
  end

  def watermark_image(filename, content_type)
    temp_file = nil
    output_temp = nil
    backup_key = nil

    begin
      # Create backup first (optional but recommended)
      backup_key = create_backup(filename)
      
      # Download original
      temp_file = Tempfile.new(['original', File.extname(filename)], binmode: true)
      s3_client.get_object(response_target: temp_file.path, bucket: ENV["S3_BUCKET_NAME"], key: filename)

      if File.extname(filename).downcase == '.heic'
        Rails.logger.info "Converting HEIC to JPEG using MiniMagick: #{temp_file.path}"
        image = MiniMagick::Image.open(temp_file.path)
        image.auto_orient
        image.strip
        image.rotate(90) if image[:width] > image[:height]

        converted = Tempfile.new(['converted', '.jpg'], binmode: true)
        image.format("jpg")
        image.write(converted.path)

        temp_file.close
        temp_file = File.open(converted.path, 'rb')
        content_type = 'image/jpeg'
      end

      original = Vips::Image.new_from_file(temp_file.respond_to?(:path) ? temp_file.path : temp_file, access: :sequential)

      # Rotate and prepare the watermark for all image types
      watermark_path = Rails.root.join("app/assets/images/watermark2.png")
      unless File.exist?(watermark_path)
        Rails.logger.error "Watermark file not found: #{watermark_path}"
        return
      end

      watermark = Vips::Image.new_from_file(watermark_path.to_s)

      # Rotate watermark 90 degrees once
      watermark = watermark.rot90

      # Ensure watermark has alpha channel
      watermark = watermark.bandjoin(255) unless watermark.has_alpha?

      # Scale watermark to ~40% of the original image width
      scale = (original.width * 0.4) / watermark.width
      watermark = watermark.resize(scale)

      # Adjust opacity to match HEIC (keep current visible strength)
      watermark = watermark * [1, 1, 1, 0.3]

      # Tile watermark across image
      tiles_x = (original.width / watermark.width.to_f).ceil + 1
      tiles_y = (original.height / watermark.height.to_f).ceil + 1

      # Create a blank watermark canvas
      watermark_canvas = Vips::Image.black(original.width, original.height).bandjoin([0, 0, 0, 0])

      tiles_y.times do |y|
        tiles_x.times do |x|
          x_offset = (x * watermark.width).to_i
          y_offset = (y * watermark.height).to_i
          watermark_canvas = watermark_canvas.composite2(watermark, :over, x: x_offset, y: y_offset)
        end
      end

      # Composite the tiled watermark over the original image
      composed = original.composite2(watermark_canvas, :over, x: 0, y: 0)

      # Save processed image
      output_temp = Tempfile.new(['watermarked', '.jpg'], binmode: true)
      composed.write_to_file(output_temp.path)

      # Validate the output file
      unless File.exist?(output_temp.path) && File.size(output_temp.path) > 0
        raise "Watermarked file is empty or doesn't exist"
      end

      # Upload watermarked version (overwrites original)
      s3_client.put_object(
        bucket: ENV["S3_BUCKET_NAME"],
        key: filename,
        body: File.open(output_temp.path),
        content_type: content_type,
        metadata: {
          'watermarked' => 'true',
          'processed_at' => Time.current.iso8601,
          'backup_key' => backup_key || 'none'
        }
      )

      Rails.logger.info "Successfully watermarked image: #{filename}"
      
      # Clean up backup after successful processing (optional)
      delete_backup(backup_key) if backup_key

    rescue => e
      Rails.logger.error "Image watermarking failed for #{filename}: #{e.message}"
      
      # Restore from backup if processing failed
      restore_from_backup(filename, backup_key) if backup_key
      
      raise e
    ensure
      # Always clean up temp files
      cleanup_temp_file(temp_file)
      cleanup_temp_file(output_temp)
    end
  end

  def watermark_video(filename, content_type)
    temp_input = nil
    temp_output = nil
    backup_key = nil

    begin
      # Create backup first
      backup_key = create_backup(filename)
      Rails.logger.info "Created backup for #{filename}: #{backup_key}"
      
      temp_input = Tempfile.new(['input', File.extname(filename)], binmode: true)
      s3_client.get_object(response_target: temp_input.path, bucket: ENV["S3_BUCKET_NAME"], key: filename)
      Rails.logger.info "Downloaded original video: #{filename}"

      output_filename = filename
      temp_output = Tempfile.new(['output', '.mp4'], binmode: true)

      watermark_path = Rails.root.join("app/assets/images/watermark2.png")
      unless File.exist?(watermark_path)
        Rails.logger.error "Video watermark file not found: #{watermark_path}"
        return
      end
      Rails.logger.info "Using watermark file at: #{watermark_path}"

      # More robust FFmpeg command with error handling
      ffmpeg_cmd = [
        "ffmpeg",
        "-i", temp_input.path,
        "-i", watermark_path.to_s,
        "-filter_complex", "[1:v]scale=iw/2:-1,transpose=1[wm];[0:v][wm]overlay=0:0:format=auto,format=yuv420p",
        "-c:a", "copy",
        "-y",
        temp_output.path
      ]

      Rails.logger.info "Executing FFmpeg command: #{ffmpeg_cmd.join(' ')}"

      # Execute FFmpeg with proper error handling
      result = system(*ffmpeg_cmd)
      
      unless result && File.exist?(temp_output.path) && File.size(temp_output.path) > 0
        raise "FFmpeg processing failed or produced empty file"
      end

      # Upload watermarked version
      s3_client.put_object(
        bucket: ENV["S3_BUCKET_NAME"],
        key: output_filename,
        body: File.open(temp_output.path),
        content_type: "video/mp4",
        metadata: {
          'watermarked' => 'true',
          'processed_at' => Time.current.iso8601,
          'backup_key' => backup_key || 'none'
        }
      )
      Rails.logger.info "Uploaded watermarked video as #{output_filename}"
      Rails.logger.info "Successfully watermarked and converted video to: #{output_filename}"
      # The original video is now overwritten; do not delete it.

      Rails.logger.info "Attaching new .mp4 blob to ActiveStorage: #{output_filename}"
      # Attach the new .mp4 blob to ActiveStorage if applicable
      # blob = ActiveStorage::Blob.create_and_upload!(
      #   io: File.open(temp_output.path),
      #   filename: File.basename(output_filename),
      #   content_type: "video/mp4",
      #   key: SecureRandom.uuid,
      #   metadata: {
      #     watermarked: 'true',
      #     processed_at: Time.current.iso8601
      #   }
      # )

      # # Attach the blob to the Visit model if found
      # visit = Visit.joins(video_attachment: :blob).find_by(active_storage_blobs: { filename: blob.filename.to_s })
      # visit.video.attach(blob) if visit

      delete_backup(backup_key) if backup_key
    rescue => e
      Rails.logger.error "Video watermarking failed for #{filename}: #{e.message}"
      
      # Restore from backup if processing failed
      restore_from_backup(filename, backup_key) if backup_key
      
      raise e
    ensure
      cleanup_temp_file(temp_input)
      cleanup_temp_file(temp_output)
    end
  end

  def create_backup(filename)
    backup_key = "backups/#{filename}"
    
    s3_client.copy_object(
      bucket: ENV["S3_BUCKET_NAME"],
      copy_source: "#{ENV['S3_BUCKET_NAME']}/#{filename}",
      key: backup_key
    )
    
    backup_key
  rescue => e
    Rails.logger.warn "Failed to create backup for #{filename}: #{e.message}"
    nil
  end

  def restore_from_backup(filename, backup_key)
    return unless backup_key
    
    s3_client.copy_object(
      bucket: ENV["S3_BUCKET_NAME"],
      copy_source: "#{ENV['S3_BUCKET_NAME']}/#{backup_key}",
      key: filename
    )
    
    Rails.logger.info "Restored #{filename} from backup"
  rescue => e
    Rails.logger.error "Failed to restore from backup: #{e.message}"
  end

  def delete_backup(backup_key)
    return unless backup_key
    
    s3_client.delete_object(bucket: ENV["S3_BUCKET_NAME"], key: backup_key)
  rescue => e
    Rails.logger.warn "Failed to delete backup #{backup_key}: #{e.message}"
  end

  def cleanup_temp_file(temp_file)
    return unless temp_file
    
    temp_file.close unless temp_file.closed?
    temp_file.unlink if File.exist?(temp_file.path)
  rescue => e
    Rails.logger.warn "Failed to cleanup temp file: #{e.message}"
  end
end