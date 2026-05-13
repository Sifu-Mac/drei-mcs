class Task < ApplicationRecord
  STATUS_VALUES = { inbox: 0, planned: 1, ready: 2, in_progress: 3, blocked: 4, review: 5, done: 6 }.freeze
  STATUS_LABELS = {
    "inbox" => "Inbox",
    "planned" => "Planned",
    "ready" => "Ready",
    "in_progress" => "In Progress",
    "blocked" => "Blocked",
    "review" => "Review",
    "done" => "Done"
  }.freeze
  STATUS_COLORS = {
    "inbox" => "#666",
    "planned" => "#94a3b8",
    "ready" => "#60a5fa",
    "in_progress" => "#fbbf24",
    "blocked" => "#ef4444",
    "review" => "#a78bfa",
    "done" => "#34d399"
  }.freeze
  OWNER_VALUES = { sifu: 0, james: 1, codex: 2 }.freeze
  OWNER_LABELS = {
    "sifu" => "Sifu",
    "james" => "James",
    "codex" => "Codex"
  }.freeze

  belongs_to :user
  belongs_to :board
  has_many :activities, class_name: "TaskActivity", dependent: :destroy
  has_many :subtasks, dependent: :destroy

  enum :priority, { none: 0, low: 1, medium: 2, high: 3 }, default: :none, prefix: true
  enum :status, STATUS_VALUES, default: :inbox
  enum :owner, OWNER_VALUES, default: :sifu, prefix: true

  validates :name, presence: true
  validates :priority, inclusion: { in: priorities.keys }
  validates :status, inclusion: { in: statuses.keys }
  validates :owner, inclusion: { in: owners.keys }

  # Activity tracking - must be declared before callbacks that use it
  attr_accessor :activity_source, :actor_name, :actor_emoji, :activity_note

  # Store activity_source before commit so it survives the transaction
  before_save :store_activity_source_for_broadcast

  # Real-time broadcasts to user's board (only for API/background changes)
  # Skip broadcasts when activity_source is "web" since the UI already handles it
  after_create_commit :broadcast_create
  after_update_commit :broadcast_update
  after_destroy_commit :broadcast_destroy
  after_create :record_creation_activity
  after_update :record_update_activities

  # Position management - acts_as_list functionality without the gem
  before_create :set_position
  before_validation :sync_blocked_and_status
  before_save :sync_completed_with_status
  before_update :track_completion_time, if: :will_save_change_to_status?

  # Order incomplete tasks by position, completed tasks by completion time (most recent first)
  scope :incomplete, -> { where(completed: false).reorder(position: :asc) }
  scope :completed, -> { where(completed: true).reorder(completed_at: :desc) }
  scope :assigned_to_agent, -> { where(assigned_to_agent: true).reorder(assigned_at: :asc) }
  scope :unassigned, -> { where(assigned_to_agent: false) }
  default_scope { order(completed: :asc, position: :asc) }

  # Agent assignment methods
  def assign_to_agent!
    update!(assigned_to_agent: true, assigned_at: Time.current)
  end

  def unassign_from_agent!
    update!(assigned_to_agent: false, assigned_at: nil)
  end

  def status_label
    STATUS_LABELS[status] || status.to_s.titleize
  end

  def owner_label
    OWNER_LABELS[owner] || owner.to_s.titleize
  end

  private

  def sync_blocked_and_status
    if status == "done"
      self.blocked = false
    elsif blocked?
      self.status = "blocked" unless status == "done"
    elsif status == "blocked"
      self.blocked = true
    else
      self.blocked = false
    end
  end

  def set_position
    return if position.present?

    # Append: set position to end of list
    max_position = board.tasks.where(status: status).maximum(:position) || 0
    self.position = max_position + 1
  end

  def store_activity_source_for_broadcast
    @stored_activity_source = activity_source
  end

  def skip_broadcast?
    @stored_activity_source == "web" || activity_source == "web"
  end

  def sync_completed_with_status
    self.completed = (status == "done")
  end

  def track_completion_time
    if status == "done"
      self.completed_at = Time.current
    else
      self.completed_at = nil
    end
  end

  def record_creation_activity
    TaskActivity.record_creation(self, source: activity_source || "web", actor_name: actor_name, actor_emoji: actor_emoji, note: activity_note)
  end

  def record_update_activities
    source = activity_source || "web"

    # Track status/column changes
    if saved_change_to_status?
      old_status, new_status = saved_change_to_status
      TaskActivity.record_status_change(self, old_status: old_status, new_status: new_status, source: source, actor_name: actor_name, actor_emoji: actor_emoji, note: activity_note)
    end

    # Track field changes
    tracked_changes = saved_changes.slice(*TaskActivity::TRACKED_FIELDS)
    TaskActivity.record_changes(self, tracked_changes, source: source, actor_name: actor_name, actor_emoji: actor_emoji, note: activity_note) if tracked_changes.any?
  end

  # Turbo Streams broadcasts for real-time updates
  def broadcast_create
    return if skip_broadcast?

    broadcast_to_board(
      action: :prepend,
      target: "column-#{status}",
      partial: "boards/task_card",
      locals: { task: self }
    )
    broadcast_column_count(status)
  end

  def broadcast_update
    return if skip_broadcast?

    # If status changed, handle move between columns
    if saved_change_to_status?
      old_status, new_status = saved_change_to_status
      # Remove from old column
      broadcast_to_board(action: :remove, target: "task_#{id}")
      # Add to new column
      broadcast_to_board(
        action: :prepend,
        target: "column-#{new_status}",
        partial: "boards/task_card",
        locals: { task: self }
      )
      broadcast_column_count(old_status)
      broadcast_column_count(new_status)
    else
      # Just update the card in place
      broadcast_to_board(
        action: :replace,
        target: "task_#{id}",
        partial: "boards/task_card",
        locals: { task: self }
      )
    end
  end

  def broadcast_destroy
    return if skip_broadcast?

    # Cache values before they become inaccessible
    cached_board_id = board_id
    cached_status = status
    cached_id = id
    stream = "board_#{cached_board_id}"

    Turbo::StreamsChannel.broadcast_action_to(stream, action: :remove, target: "task_#{cached_id}")

    # Update column count
    count = Board.find(cached_board_id).tasks.where(status: cached_status).count
    Turbo::StreamsChannel.broadcast_action_to(
      stream,
      action: :replace,
      target: "column-#{cached_status}-count",
      html: %(<span id="column-#{cached_status}-count" style="font-size:11px;font-weight:600;color:#444;background:rgba(255,255,255,0.04);padding:0 7px;border-radius:5px;line-height:20px">#{count}</span>)
    )
  end

  def broadcast_column_count(column_status)
    count = board.tasks.where(status: column_status).count
    broadcast_to_board(
      action: :replace,
      target: "column-#{column_status}-count",
      html: %(<span id="column-#{column_status}-count" style="font-size:11px;font-weight:600;color:#444;background:rgba(255,255,255,0.04);padding:0 7px;border-radius:5px;line-height:20px">#{count}</span>)
    )
  end

  def board_stream_name
    "board_#{board_id}"
  end

  def broadcast_to_board(action:, target:, **options)
    Turbo::StreamsChannel.broadcast_action_to(board_stream_name, action: action, target: target, **options)
  end
end
