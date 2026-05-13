class TaskComment < ApplicationRecord
  belongs_to :task
  belongs_to :user

  validates :body, presence: true, length: { maximum: 5000 }

  scope :chronological, -> { order(created_at: :asc) }

  def author_label
    user&.agent_name.presence || user&.email_address.to_s.split("@").first.presence || "Unknown"
  end
end
