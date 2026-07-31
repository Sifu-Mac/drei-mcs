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
    if images.size > MediaUploadValidator::MAX_COMMENT_IMAGES
      errors.add(:images, "must contain no more than #{MediaUploadValidator::MAX_COMMENT_IMAGES} images")
    end

    images.each do |image|
      MediaUploadValidator.validate_image(self, image, attribute: :images)
    end
  end
end
