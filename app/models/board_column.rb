class BoardColumn < ApplicationRecord
  KIND_LABELS = {
    "backlog" => "Backlog",
    "active" => "Aktiv",
    "review" => "Prüfung",
    "blocked" => "Blockiert",
    "done" => "Erledigt"
  }.freeze

  belongs_to :board
  has_many :tasks, dependent: :restrict_with_error

  enum :kind, { backlog: 0, active: 1, review: 2, blocked: 3, done: 4 }, prefix: true

  validates :name, presence: true
  validates :kind, presence: true
  validates :position, presence: true, uniqueness: { scope: :board_id }

  before_validation :set_position, on: :create
  after_update :sync_task_states, if: :saved_change_to_kind?
  after_commit :broadcast_board_refresh

  scope :ordered, -> { order(position: :asc, created_at: :asc) }

  def self.standard_review_template
    [
      ["Eingang", "backlog"],
      ["In Bearbeitung", "active"],
      ["Kunden-Review", "review"],
      ["Änderungen angefordert", "blocked"],
      ["Freigegeben", "done"]
    ]
  end

  def self.simple_template
    [
      ["Offen", "backlog"],
      ["Review", "review"],
      ["Erledigt", "done"]
    ]
  end

  def self.template_for(template)
    template.to_s == "simple" ? simple_template : standard_review_template
  end

  def kind_label
    KIND_LABELS[kind] || kind.to_s.humanize
  end

  def move_left!
    swap_with(board.board_columns.where("position < ?", position).ordered.last)
  end

  def move_right!
    swap_with(board.board_columns.where("position > ?", position).ordered.first)
  end

  private

  def broadcast_board_refresh
    Turbo::StreamsChannel.broadcast_action_to("board_#{board_id}", action: :refresh)
  end

  def set_position
    return if position.present? && position.positive?

    self.position = (board.board_columns.maximum(:position) || 0) + 1
  end

  def sync_task_states
    Task.unscoped.where(board_column_id: id).find_each(&:save!)
  rescue ActiveRecord::RecordInvalid => error
    errors.add(:base, "Kartenstatus konnte nicht synchronisiert werden: #{error.record.errors.full_messages.join(", ")}")
    raise ActiveRecord::Rollback
  end

  def swap_with(other)
    return unless other

    BoardColumn.transaction do
      current_position = position
      other_position = other.position
      update_column(:position, 0)
      other.update!(position: current_position)
      update!(position: other_position)
    end
    reload
  end
end
