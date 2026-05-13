class Board < ApplicationRecord
  belongs_to :user
  has_many :tasks, dependent: :destroy

  validates :name, presence: true
  validates :position, presence: true

  before_create :set_position

  # Default scope orders by position
  default_scope { order(position: :asc) }

  # Available board colors (Tailwind-compatible)
  COLORS = %w[gray red orange amber yellow lime green emerald teal cyan sky blue indigo violet purple fuchsia pink rose].freeze

  # Available board icons (emojis)
  DEFAULT_ICONS = %w[📋 📝 🎯 🚀 💡 🔧 📊 🎨 📚 🏠 💼 🎮 🎵 📸 ✨ 🦞].freeze

  def self.create_onboarding_for(user)
    board = user.boards.create!(
      name: "Getting Started",
      icon: "🚀",
      color: "blue"
    )

    tasks = [
      {
        name: "👋 Welcome to Mission Control!",
        description: "This is your shared operating board for projects, tasks and agent work. Move cards through the workflow and keep owners explicit.",
        status: "ready",
        position: 0
      },
      {
        name: "🔗 Connect your agent",
        description: "Go to Settings → copy the integration prompt → paste it into your agent config. Once connected, you'll see the agent in the header.",
        status: "inbox",
        position: 0
      },
      {
        name: "✅ Assign your first task",
        description: "Create a task, set the owner, then assign it when an agent should execute it. Watch the activity feed for updates.",
        status: "inbox",
        position: 1
      },
      {
        name: "💡 Example: Research task",
        description: "\"Research the top 5 competitors to [product] and summarize their pricing models.\" — Great for agents with web access.",
        status: "inbox",
        position: 2
      },
      {
        name: "💡 Example: Code task",
        description: "\"Add a dark mode toggle to the settings page. Use Tailwind classes.\" — Perfect for coding agents.",
        status: "inbox",
        position: 3
      },
      {
        name: "💡 Example: Writing task",
        description: "\"Draft a welcome email for new users. Keep it short, friendly, 3 paragraphs max.\" — Works with any agent.",
        status: "inbox",
        position: 4
      },
      {
        name: "🎯 Try it yourself!",
        description: "Delete these cards and create your first real task. Keep scope and ownership clear.",
        status: "ready",
        position: 1
      }
    ]

    tasks.each do |task_attrs|
      board.tasks.create!(task_attrs.merge(user: user))
    end

    board
  end

  private

  def set_position
    return if position.present? && position > 0

    max_position = user.boards.unscoped.where(user_id: user_id).maximum(:position) || 0
    self.position = max_position + 1
  end
end
