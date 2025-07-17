require 'open-uri'
require 'vips'
require 'mini_magick'
require 'hexapdf'

class Visit < ApplicationRecord
  has_many_attached :images, dependent: :purge_later
  has_one_attached :visit_pdf, dependent: :purge_later

  has_one_attached :video, dependent: :purge_later

  belongs_to :dress, optional: true
  belongs_to :user

  validates :user_id, presence: true

  def convert_heic_to_jpg(tempfile)
    image = MiniMagick::Image.open(tempfile.path)
    image.auto_orient
    image.strip
    image.rotate(90) if image[:width] > image[:height]

    jpg_file = Tempfile.new(['converted', '.jpg'], binmode: true)
    image.format("jpg")
    image.write(jpg_file.path)
    jpg_file
  end

  def all_images_watermarked?
    images.all? { |image| watermarked_version_exists?(image) }
  end
  
  def watermarked_version_exists?(image)
    # Use the image's key to check if it's watermarked
    already_watermarked?(image.key)
  end
  
  def mark_ready!(cc_emails: [])
    update!(processed: true)
    # Trigger your email/notifications here
    NotificationMailer.with(
      user: user,
      visit_id: id,
      cc_emails: cc_emails
    ).job_completion_email.deliver_later
  end

  def s3_client
    @s3_client ||= Aws::S3::Client.new(
      region: ENV["AWS_REGION"],
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
    )
  end

  def already_watermarked?(filename)
    response = s3_client.head_object(bucket: ENV["S3_BUCKET_NAME"], key: filename)
    response.metadata['watermarked'] == 'true'
  rescue Aws::S3::Errors::NotFound
    false
  end
end