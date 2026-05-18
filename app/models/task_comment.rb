class TaskComment < ApplicationRecord
  belongs_to :task
  belongs_to :user

  validates :body, presence: true, length: { maximum: 5000 }

  scope :chronological, -> { order(created_at: :asc) }

  def author_label
    return user.email_address.to_s.split("@").first.tr("._-", " ").titleize if user&.email_address.present?
    return user.agent_name if user&.agent_name.present?

    "Unknown"
  end
end
