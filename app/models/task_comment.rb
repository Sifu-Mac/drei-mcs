class TaskComment < ApplicationRecord
  belongs_to :task
  belongs_to :user
  belongs_to :quoted_comment, class_name: "TaskComment", optional: true
  has_many_attached :images

  validates :body, presence: true, length: { maximum: 5000 }
  validate :quoted_comment_belongs_to_task
  validate :images_are_supported

  before_validation :capture_quoted_comment_snapshot, if: :quoted_comment_id?

  scope :chronological, -> { order(created_at: :asc) }

  def author_label
    user&.display_label || "Unbekannt"
  end

  def quoted_author_label
    quoted_comment_author_label.presence || quoted_comment&.author_label || "Unknown"
  end

  def quoted_body
    quoted_comment_body.presence || quoted_comment&.body
  end

  private

  def capture_quoted_comment_snapshot
    return unless quoted_comment

    self.quoted_comment_body ||= quoted_comment.body
    self.quoted_comment_author_label ||= quoted_comment.author_label
    self.quoted_comment_created_at ||= quoted_comment.created_at
  end

  def quoted_comment_belongs_to_task
    return unless quoted_comment

    errors.add(:quoted_comment, "must belong to the same task") unless quoted_comment.task_id == task_id
  end

  def images_are_supported
    if images.size > MediaUploadValidator::MAX_COMMENT_IMAGES
      errors.add(:images, "must contain no more than #{MediaUploadValidator::MAX_COMMENT_IMAGES} images")
    end

    images.each do |image|
      MediaUploadValidator.validate_image(self, image, attribute: :images)
    end
  end
end
