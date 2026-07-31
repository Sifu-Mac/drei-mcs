class WorkspaceMembership < ApplicationRecord
  belongs_to :workspace
  belongs_to :user

  # owner/member remain readable for historic records only. New memberships are clients.
  enum :role, { owner: 0, member: 1, client: 2 }, default: :client

  validates :user_id, uniqueness: { scope: :workspace_id }
end
