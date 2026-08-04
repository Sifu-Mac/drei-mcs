class Board < ApplicationRecord
  belongs_to :user
  belongs_to :workspace
  belongs_to :campaign
  has_many :board_columns, dependent: :destroy
  has_many :tasks, dependent: :destroy

  attr_accessor :column_template

  validates :name, presence: true
  validates :position, presence: true

  before_validation :ensure_campaign, on: :create
  before_create :set_position
  after_create :create_template_columns

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
      color: "blue",
      column_template: "standard_review"
    )

    active_column = board.column_for_legacy_status("ready")
    backlog_column = board.column_for_legacy_status("inbox")

    tasks = [
      {
        name: "Willkommen bei DREI Asset Review",
        description: "Dies ist das gemeinsame Arbeitsboard für Kampagnen, Assets und Reviews. Verschiebe Karten durch den Workflow und halte Verantwortlichkeiten klar fest.",
        board_column: active_column,
        position: 0
      },
      {
        name: "Integration vorbereiten",
        description: "Verbinde eine passende Integration, wenn sie für den Arbeitsablauf benötigt wird.",
        board_column: backlog_column,
        position: 0
      },
      {
        name: "Erste Karte erstellen",
        description: "Erstelle eine Karte und verschiebe sie durch den gemeinsamen Workflow.",
        board_column: backlog_column,
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

  def column_for_legacy_status(status)
    kind = Task.legacy_status_to_column_kind(status)
    board_columns.ordered.find_by(kind: BoardColumn.kinds.fetch(kind)) || board_columns.ordered.first
  end

  def duplicate_to!(campaign:, user: self.user)
    Board.transaction do
      copy = campaign.workspace.boards.new(
        user: user,
        campaign: campaign,
        name: "#{name} Kopie",
        icon: icon,
        color: color
      )
      copy.column_template = "skip"
      copy.save!

      column_map = {}
      board_columns.ordered.each do |column|
        copied_column = copy.board_columns.create!(name: column.name, kind: column.kind, position: column.position)
        column_map[column.id] = copied_column
      end

      tasks.unscoped.where(board_id: id, archived_at: nil).reorder(:position, :created_at).find_each do |task|
        new_task = task.dup
        new_task.board = copy
        new_task.board_column = column_map.fetch(task.board_column_id)
        new_task.user = task.user || user
        new_task.archived_at = nil
        new_task.activity_source = "web"
        new_task.save!
        new_task.activities.delete_all
        task.subtasks.order(:position).each do |subtask|
          new_task.subtasks.create!(title: subtask.title, position: subtask.position, done: false)
        end
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

  def create_template_columns
    return if column_template == "skip" || board_columns.exists?

    BoardColumn.template_for(column_template).each_with_index do |(column_name, column_kind), index|
      board_columns.create!(name: column_name, kind: column_kind, position: index + 1)
    end
  end
end
