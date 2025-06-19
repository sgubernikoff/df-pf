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

    temp_file = Tempfile.new
    s3.get_object(response_target: temp_file.path, bucket: ENV["S3_BUCKET_NAME"], key: filename)

    original = Vips::Image.new_from_file(temp_file.path, access: :sequential)

    watermark_path = Rails.root.join("app/assets/images/watermark2.png")
    return unless File.exist?(watermark_path)

    watermark = Vips::Image.new_from_file(watermark_path.to_s)
    watermark = watermark.resize(original.height.to_f / watermark.height)
    watermark = watermark.bandjoin(255) unless watermark.has_alpha?
    watermark = watermark * [1, 1, 1, 0.5] # 50% opacity for visibility

    composed = original.composite2(watermark, :over,
      x: (original.width - watermark.width) / 2,
      y: (original.height - watermark.height) / 2)

    output_path = temp_file.path
    composed.write_to_file(output_path)

    s3.put_object(
      bucket: ENV["S3_BUCKET_NAME"],
      key: filename,
      body: File.open(output_path),
      content_type: content_type
    )

    temp_file.close
    temp_file.unlink
  end

  def watermark_video(filename, content_type)
    s3 = Aws::S3::Client.new(
      region: ENV["AWS_REGION"],
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
    )

    temp_input = Tempfile.new(['input', File.extname(filename)], binmode: true)
    temp_output = Tempfile.new(['output', '.mp4'], binmode: true)

    s3.get_object(response_target: temp_input.path, bucket: ENV["S3_BUCKET_NAME"], key: filename)

    watermark_path = Rails.root.join("app/assets/images/video_watermark.png")
    return unless File.exist?(watermark_path)

    system("ffmpeg -i #{Shellwords.escape(temp_input.path)} -i #{Shellwords.escape(watermark_path.to_s)} -filter_complex \"[1][0]scale2ref=w=iw:h=ih[wm][vid];[vid][wm]overlay=0:0\" -c:a copy #{Shellwords.escape(temp_output.path)} -y")

    s3.put_object(
      bucket: ENV["S3_BUCKET_NAME"],
      key: filename,
      body: File.open(temp_output.path),
      content_type: content_type
    )

    temp_input.close
    temp_input.unlink
    temp_output.close
    temp_output.unlink
  end
end