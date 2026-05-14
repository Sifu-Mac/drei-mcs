class WorkspaceMembership < ApplicationRecord
  belongs_to :workspace
  belongs_to :user

  enum :role, { owner: 0, member: 1 }, default: :member

  validates :user_id, uniqueness: { scope: :workspace_id }
end
