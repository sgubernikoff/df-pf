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

      # Process image
      original = Vips::Image.new_from_file(temp_file.path, access: :sequential)
      watermark_path = Rails.root.join("app/assets/images/watermark2.png")
      
      unless File.exist?(watermark_path)
        Rails.logger.error "Watermark file not found: #{watermark_path}"
        return
      end

      watermark = Vips::Image.new_from_file(watermark_path.to_s)
      
      # Resize watermark to match original image dimensions exactly
      watermark = watermark.resize(original.width.to_f / watermark.width)
                          .resize(original.height.to_f / watermark.height)
      
      # Ensure watermark has alpha channel
      watermark = watermark.bandjoin(255) unless watermark.has_alpha?
      
      # Apply opacity (adjust 0.3 for less opacity, 0.7 for more)
      watermark = watermark * [1, 1, 1, 2]

      # Composite watermark over entire image
      composed = original.composite2(watermark, :over, x: 0, y: 0)

      # Save processed image
      output_temp = Tempfile.new(['watermarked', File.extname(filename)], binmode: true)
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
      # delete_backup(backup_key) if backup_key

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

      output_filename = filename.sub(/\.\w+$/, '.mp4')
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
        "-filter_complex", "[0:v][1:v]overlay=0:0:alpha=0.5",
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
      # Delete the original video after successful watermarking
      s3_client.delete_object(bucket: ENV["S3_BUCKET_NAME"], key: filename)
      Rails.logger.info "Deleted original video: #{filename}"

      Rails.logger.info "Attaching new .mp4 blob to ActiveStorage: #{output_filename}"
      # Generate a unique key for the watermarked file to avoid duplicate keys
      unique_key = "#{File.basename(output_filename, '.*')}_#{SecureRandom.uuid}.mp4"
      # Attach the new .mp4 blob to ActiveStorage if applicable
      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(temp_output.path),
        filename: unique_key,
        content_type: "video/mp4",
        key: unique_key,
        metadata: {
          watermarked: 'true',
          processed_at: Time.current.iso8601
        }
      )

      # If your model should be updated here, fetch and attach it:
      # Example (you'll need to adjust based on how you associate blobs with models):
      # visit = Visit.find_by_filename(filename)
      # visit.video.attach(blob)

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