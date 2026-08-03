class User < ApplicationRecord
  has_secure_password validations: false

  has_many :sessions, dependent: :destroy
  has_many :boards, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :task_comments, dependent: :destroy
  has_many :api_tokens, dependent: :destroy
  has_many :workspace_memberships, dependent: :destroy
  has_many :workspaces, through: :workspace_memberships
  has_many :owned_workspaces, class_name: "Workspace", foreign_key: :owner_id, dependent: :destroy
  has_one_attached :avatar

  attr_accessor :invited_role

  # Primary API token for agent integration
  def api_token
    api_tokens.first || api_tokens.create!(name: "Default")
  end

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :display_name, with: ->(name) { name.to_s.squish.presence }

  validate :acceptable_avatar, if: :avatar_changed?
  validates :password, length: { minimum: 8 }, if: :password_required?
  validates :password, confirmation: true, if: :password_required?

  after_create :ensure_first_admin
  after_create_commit :ensure_workspace_setup

  validates :email_address, presence: true,
                           uniqueness: { case_sensitive: false },
                           format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }
  validates :display_name,
            length: { in: 2..40 },
            uniqueness: { case_sensitive: false },
            allow_nil: true

  # Returns avatar source - Active Storage attachment takes priority over URL
  def avatar_source
    if avatar.attached?
      avatar
    elsif avatar_url.present?
      avatar_url
    end
  end

  def has_avatar?
    avatar.attached? || avatar_url.present?
  end

  def display_label
    return display_name if display_name.present?
    return email_address.to_s.split("@").first.tr("._-", " ").titleize if email_address.present?
    return agent_name if agent_name.present?

    "Unbekannt"
  end

  # Check if user has a password set
  def password_user?
    password_digest.present?
  end

  def accessible_boards
    Board.joins(workspace: :workspace_memberships)
         .joins(:campaign)
         .where(workspace_memberships: { user_id: id }, campaigns: { archived_at: nil })
         .distinct
  end

  def accessible_tasks
    Task.joins(board: [:campaign, { workspace: :workspace_memberships }])
        .where(workspace_memberships: { user_id: id }, campaigns: { archived_at: nil }, boards: { archived_at: nil })
        .distinct
  end

  def current_workspace_campaigns
    current_workspace&.campaigns&.active&.ordered || Campaign.none
  end

  def current_workspace_boards
    Board.joins(:campaign)
         .where(workspace_id: current_workspace&.id, campaigns: { archived_at: nil })
  end

  def current_workspace_tasks
    Task.joins(board: :campaign)
        .where(boards: { workspace_id: current_workspace&.id, archived_at: nil }, campaigns: { archived_at: nil })
        .distinct
  end

  def current_workspace
    collaboration_workspace || owned_workspaces.ordered.first || workspaces.ordered.first
  end

  def collaboration_workspace
    workspaces
      .left_joins(:workspace_memberships)
      .group("workspaces.id")
      .order(Arel.sql("COUNT(workspace_memberships.id) DESC"), :created_at)
      .first
  end

  def workspace_owner?(workspace)
    workspace_memberships.find_by(workspace_id: workspace.id)&.owner?
  end

  private

  def password_required?
    new_record? || password.present?
  end

  def ensure_workspace_setup
    workspace = Workspace.primary_collaboration_workspace

    if workspace.nil?
      workspace = owned_workspaces.create!(name: "DREI Asset Review")
      Board.create_onboarding_for(self, workspace: workspace)
      return
    end

    workspace.add_member(self, role: invited_role || :member) unless workspace.members.exists?(id: id)
  end

  def ensure_first_admin
    self.update_column(:admin, true) if User.where(admin: true).where.not(id: id).none?
  end

  def avatar_changed?
    avatar.attached? && avatar.attachment.new_record?
  end

  def acceptable_avatar
    MediaUploadValidator.validate_image(
      self,
      avatar,
      attribute: :avatar,
      max_size: 512.kilobytes,
      allowed_types: %w[image/jpeg image/png image/webp]
    )
    return if errors[:avatar].any?

    return unless avatar.blob.representable?
    return unless avatar.blob.metadata.present?

    metadata = avatar.blob.metadata
    width = metadata[:width]
    height = metadata[:height]

    if width.present? && height.present? && (width > 256 || height > 256)
      errors.add(:avatar, "dimensions must not exceed 256x256 pixels")
    end
  end
end
