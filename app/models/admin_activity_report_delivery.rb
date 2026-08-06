class AdminActivityReportDelivery < ApplicationRecord
  belongs_to :user

  validates :period_start_at, :period_end_at, presence: true
  validates :period_end_at, uniqueness: { scope: :user_id }
end
