class Board < ApplicationRecord
  belongs_to :user
  belongs_to :workspace
  belongs_to :campaign
  has_many :tasks, dependent: :destroy

  validates :name, presence: true
  validates :position, presence: true

  before_validation :ensure_campaign, on: :create
  before_create :set_position

  default_scope { where(archived_at: nil).order(position: :asc) }
  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :ordered, -> { order(position: :asc, created_at: :asc) }

  COLORS = %w[gray red orange amber yellow lime green emerald teal cyan sky blue indigo violet purple fuchsia pink rose].freeze
  DEFAULT_ICONS = %w[📋 📝 🎯 🚀 💡 🔧 📊 🎨 📚 🏠 💼 🎮 🎵 📸 ✨ 🦞].freeze

  def self.create_onboarding_for(user, workspace: user.current_workspace)
    campaign = workspace.campaigns.active.find_or_create_by!(name: "Allgemein")

    board = workspace.boards.create!(
      user: user,
      campaign: campaign,
      name: "Erste Schritte",
      icon: "🚀",
      color: "blue"
    )

    tasks = [
      {
        name: "Willkommen bei DREI Asset Review",
        description: "Dies ist das gemeinsame Arbeitsboard für Kampagnen, Assets und Reviews. Verschiebe Karten durch den Workflow und halte Verantwortlichkeiten klar fest.",
        status: "ready",
        position: 0
      },
      {
        name: "Agent verbinden",
        description: "Öffne Einstellungen, kopiere den Integrations-Prompt und füge ihn in deiner Agent-Konfiguration ein.",
        status: "inbox",
        position: 0
      },
      {
        name: "Erste Karte zuweisen",
        description: "Erstelle eine Karte, setze den Owner und weise sie zu, wenn ein Agent daran arbeiten soll.",
        status: "inbox",
        position: 1
      }
    ]

    tasks.each do |task_attrs|
      board.tasks.create!(task_attrs.merge(user: user))
    end

    board
  end

  def archived?
    archived_at.present?
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def restore!
    update!(archived_at: nil)
  end

  def duplicate_to!(campaign:, user: self.user)
    Board.transaction do
      copy = campaign.workspace.boards.create!(
        user: user,
        campaign: campaign,
        name: "#{name} Kopie",
        icon: icon,
        color: color
      )

      tasks.reorder(:position, :created_at).find_each do |task|
        new_task = task.dup
        new_task.board = copy
        new_task.user = task.user || user
        new_task.activity_source = "web"
        new_task.save!
        new_task.activities.delete_all
      end

      copy
    end
  end

  private

  def ensure_campaign
    return if campaign.present? || workspace.blank?

    self.campaign = workspace.campaigns.active.find_or_create_by!(name: "Allgemein")
  end

  def set_position
    return if position.present? && position.positive?

    scope = if campaign_id.present?
      self.class.unscoped.where(campaign_id: campaign_id)
    else
      workspace.boards.unscoped.where(workspace_id: workspace_id)
    end

    self.position = (scope.maximum(:position) || 0) + 1
  end
end
