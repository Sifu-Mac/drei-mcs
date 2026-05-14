class Workspace < ApplicationRecord
  belongs_to :owner, class_name: "User"

  has_many :workspace_memberships, dependent: :destroy
  has_many :members, through: :workspace_memberships, source: :user
  has_many :boards, dependent: :destroy

  validates :name, presence: true

  scope :ordered, -> { order(created_at: :asc) }

  after_create :ensure_owner_membership

  def self.primary_collaboration_workspace
    ordered.first
  end

  def add_member(user, role: :member)
    workspace_memberships.find_or_create_by!(user: user) do |membership|
      membership.role = role
    end
  end

  private

  def ensure_owner_membership
    workspace_memberships.find_or_create_by!(user: owner) do |membership|
      membership.role = :owner
    end
  end
end
