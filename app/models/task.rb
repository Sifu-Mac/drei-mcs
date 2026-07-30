class Task < ApplicationRecord
  STATUS_VALUES = { inbox: 0, planned: 1, ready: 2, in_progress: 3, blocked: 4, review: 5, done: 6 }.freeze
  STATUS_LABELS = {
    "inbox" => "Eingang",
    "planned" => "Geplant",
    "ready" => "Bereit",
    "in_progress" => "In Bearbeitung",
    "blocked" => "Blockiert",
    "review" => "Prüfung",
    "done" => "Erledigt"
  }.freeze
  STATUS_COLORS = {
    "inbox" => "#94a3b8",
    "planned" => "#94a3b8",
    "ready" => "#60a5fa",
    "in_progress" => "#60a5fa",
    "blocked" => "#ef4444",
    "review" => "#a78bfa",
    "done" => "#34d399"
  }.freeze
  KIND_STATUS = {
    "backlog" => "inbox",
    "active" => "in_progress",
    "review" => "review",
    "blocked" => "blocked",
    "done" => "done"
  }.freeze
  STATUS_KIND = {
    "inbox" => "backlog",
    "planned" => "backlog",
    "ready" => "active",
    "in_progress" => "active",
    "blocked" => "blocked",
    "review" => "review",
    "done" => "done"
  }.freeze
  COLOR_VALUES = %w[none blue green yellow orange red purple gray].freeze
  COLOR_LABELS = {
    "none" => "Keine Farbe",
    "blue" => "Blau",
    "green" => "Grün",
    "yellow" => "Gelb",
    "orange" => "Orange",
    "red" => "Rot",
    "purple" => "Violett",
    "gray" => "Grau"
  }.freeze
  COLOR_STYLES = {
    "none" => nil,
    "blue" => "#1e5eff",
    "green" => "#16a34a",
    "yellow" => "#eab308",
    "orange" => "#f97316",
    "red" => "#ef4444",
    "purple" => "#7c3aed",
    "gray" => "#6b7280"
  }.freeze
  OWNER_VALUES = { sifu: 0, james: 1, codex: 2 }.freeze
  OWNER_LABELS = {
    "sifu" => "Sifu",
    "james" => "James",
    "codex" => "Codex"
  }.freeze

  belongs_to :user
  belongs_to :board
  belongs_to :board_column
  has_many :activities, class_name: "TaskActivity", dependent: :destroy
  has_many :comments, class_name: "TaskComment", dependent: :destroy
  has_many :subtasks, dependent: :destroy
  has_one_attached :cover_image

  enum :priority, { none: 0, low: 1, medium: 2, high: 3 }, default: :none, prefix: true
  enum :status, STATUS_VALUES, default: :inbox
  enum :owner, OWNER_VALUES, default: :sifu, prefix: true

  validates :name, presence: true
  validates :priority, inclusion: { in: priorities.keys }
  validates :status, inclusion: { in: statuses.keys }
  validates :owner, inclusion: { in: owners.keys }
  validates :color, inclusion: { in: COLOR_VALUES }
  validate :cover_image_is_supported
  validate :board_column_belongs_to_board

  attr_accessor :activity_source, :actor_name, :actor_emoji, :activity_note

  before_validation :ensure_board_column
  before_save :store_activity_source_for_broadcast
  before_save :sync_state_from_board_column
  after_create_commit :broadcast_create
  after_update_commit :broadcast_update
  after_destroy_commit :broadcast_destroy
  after_create :record_creation_activity
  after_update :record_update_activities
  before_create :set_position

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :incomplete, -> { where(completed: false, archived_at: nil).reorder(position: :asc) }
  scope :completed, -> { where(completed: true, archived_at: nil).reorder(completed_at: :desc) }
  scope :assigned_to_agent, -> { where(assigned_to_agent: true, archived_at: nil).reorder(assigned_at: :asc) }
  scope :unassigned, -> { where(assigned_to_agent: false, archived_at: nil) }
  default_scope { where(archived_at: nil).order(completed: :asc, position: :asc) }

  def self.legacy_status_to_column_kind(status)
    STATUS_KIND[status.to_s] || "backlog"
  end

  def self.legacy_status_for_kind(kind)
    KIND_STATUS[kind.to_s] || "inbox"
  end

  def completed?
    board_column&.kind_done? || self[:completed]
  end

  def blocked?
    board_column&.kind_blocked? || self[:blocked]
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def restore!
    update!(archived_at: nil)
  end

  def duplicate_for!(user:)
    copy = dup
    copy.name = "#{name} Kopie"
    copy.user = user
    copy.archived_at = nil
    copy.activity_source = "web"
    copy.save!
    copy.activities.delete_all
    copy
  end

  def assign_to_agent!
    update!(assigned_to_agent: true, assigned_at: Time.current)
  end

  def unassign_from_agent!
    update!(assigned_to_agent: false, assigned_at: nil)
  end

  def status_label
    board_column&.name || STATUS_LABELS[status] || status.to_s.titleize
  end

  def owner_label
    OWNER_LABELS[owner] || owner.to_s.titleize
  end

  def color_label
    COLOR_LABELS[color] || COLOR_LABELS["none"]
  end

  def color_hex
    COLOR_STYLES[color]
  end

  private

  def ensure_board_column
    return if board.blank?

    if will_save_change_to_board_column_id?
      self.board_column ||= board.board_columns.find_by(id: board_column_id)
    elsif will_save_change_to_completed?
      target_kind = self[:completed] ? :done : :backlog
      self.board_column = board.board_columns.find_by(kind: BoardColumn.kinds.fetch(target_kind)) || board.board_columns.ordered.first
    elsif will_save_change_to_blocked? && self[:blocked]
      self.board_column = board.board_columns.find_by(kind: BoardColumn.kinds[:blocked]) || board.board_columns.ordered.first
    elsif will_save_change_to_status?
      self.board_column = board.column_for_legacy_status(status)
    end

    self.board_column ||= board.column_for_legacy_status(status)
  end

  def board_column_belongs_to_board
    return if board_column.blank? || board.blank?

    errors.add(:board_column, "muss zu diesem Board gehören") unless board_column.board_id == board_id
  end

  def set_position
    return if position.present?

    self.position = (board.tasks.unscoped.where(board_column_id: board_column_id, archived_at: nil).maximum(:position) || 0) + 1
  end

  def store_activity_source_for_broadcast
    @stored_activity_source = activity_source
  end

  def skip_broadcast?
    @stored_activity_source == "web" || activity_source == "web"
  end

  def sync_state_from_board_column
    return unless board_column

    self.status = self.class.legacy_status_for_kind(board_column.kind)
    self.blocked = board_column.kind_blocked?
    was_completed = self[:completed]
    self.completed = board_column.kind_done?

    if completed?
      self.completed_at ||= Time.current
    elsif was_completed || completed_at.present?
      self.completed_at = nil
    end
  end

  def record_creation_activity
    TaskActivity.record_creation(self, source: activity_source || "web", actor_name: actor_name, actor_emoji: actor_emoji, note: activity_note)
  end

  def record_update_activities
    source = activity_source || "web"

    if saved_change_to_board_column_id?
      old_id, new_id = saved_change_to_board_column_id
      old_column = BoardColumn.find_by(id: old_id)
      new_column = BoardColumn.find_by(id: new_id)
      TaskActivity.record_column_change(self, old_column_name: old_column&.name, new_column_name: new_column&.name, source: source, actor_name: actor_name, actor_emoji: actor_emoji, note: activity_note)
    elsif saved_change_to_status?
      old_status, new_status = saved_change_to_status
      TaskActivity.record_status_change(self, old_status: old_status, new_status: new_status, source: source, actor_name: actor_name, actor_emoji: actor_emoji, note: activity_note)
    end

    tracked_changes = saved_changes.slice(*TaskActivity::TRACKED_FIELDS)
    TaskActivity.record_changes(self, tracked_changes, source: source, actor_name: actor_name, actor_emoji: actor_emoji, note: activity_note) if tracked_changes.any?
  end

  def cover_image_is_supported
    MediaUploadValidator.validate_image(self, cover_image, attribute: :cover_image)
  end

  def broadcast_create
    return if skip_broadcast?

    broadcast_to_board(action: :prepend, target: "column-#{board_column_id}", partial: "boards/task_card", locals: { task: self })
    broadcast_column_count(board_column_id)
  end

  def broadcast_update
    return if skip_broadcast?

    if saved_change_to_board_column_id? || saved_change_to_archived_at?
      old_column_id, new_column_id = saved_change_to_board_column_id || [board_column_id, board_column_id]
      broadcast_to_board(action: :remove, target: "task_#{id}")
      if archived_at.blank?
        broadcast_to_board(action: :prepend, target: "column-#{new_column_id}", partial: "boards/task_card", locals: { task: self })
      end
      broadcast_column_count(old_column_id) if old_column_id
      broadcast_column_count(new_column_id) if new_column_id
    else
      broadcast_to_board(action: :replace, target: "task_#{id}", partial: "boards/task_card", locals: { task: self })
    end
  end

  def broadcast_destroy
    return if skip_broadcast?

    cached_board_id = board_id
    cached_column_id = board_column_id
    cached_id = id
    stream = "board_#{cached_board_id}"

    Turbo::StreamsChannel.broadcast_action_to(stream, action: :remove, target: "task_#{cached_id}")
    count = Board.find(cached_board_id).tasks.where(board_column_id: cached_column_id).count
    Turbo::StreamsChannel.broadcast_action_to(stream, action: :replace, target: "column-#{cached_column_id}-count", html: %(<span id="column-#{cached_column_id}-count" style="font-size:11px;font-weight:600;color:#6b7280;background:#eef2ff;padding:0 7px;border-radius:5px;line-height:20px">#{count}</span>))
  end

  def broadcast_column_count(column_id)
    count = board.tasks.where(board_column_id: column_id).count
    broadcast_to_board(action: :replace, target: "column-#{column_id}-count", html: %(<span id="column-#{column_id}-count" style="font-size:11px;font-weight:600;color:#6b7280;background:#eef2ff;padding:0 7px;border-radius:5px;line-height:20px">#{count}</span>))
  end

  def board_stream_name
    "board_#{board_id}"
  end

  def broadcast_to_board(action:, target:, **options)
    Turbo::StreamsChannel.broadcast_action_to(board_stream_name, action: action, target: target, **options)
  end
end
