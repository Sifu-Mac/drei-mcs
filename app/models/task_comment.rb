class TaskComment < ApplicationRecord
  belongs_to :task
  belongs_to :user
  has_many_attached :images

  validates :body, presence: true, length: { maximum: 5000 }
  validate :images_are_supported

  scope :chronological, -> { order(created_at: :asc) }

  def author_label
    return user.email_address.to_s.split("@").first.tr("._-", " ").titleize if user&.email_address.present?
    return user.agent_name if user&.agent_name.present?

    "Unknown"
  end

  private

  def images_are_supported
    images.each do |image|
      unless image.blob.content_type.in?(MediaUploadValidator::ALLOWED_IMAGE_TYPES)
        errors.add(:images, "#{image.filename} must be a JPEG, PNG, WebP, or GIF image")
      end

      if image.blob.byte_size > MediaUploadValidator::MAX_IMAGE_SIZE
        errors.add(:images, "#{image.filename} must be 5 MB or smaller")
      end
    end
  end
end
