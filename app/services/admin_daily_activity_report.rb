class AdminDailyActivityReport
  COMMENT_EXCERPT_LENGTH = 180

  Movement = Data.define(:task, :actor_label, :occurred_at, :from_label, :to_label)
  Comment = Data.define(:task, :author_label, :occurred_at, :excerpt)

  attr_reader :period_start, :period_end

  def initialize(period_start:, period_end:)
    @period_start = period_start
    @period_end = period_end
  end

  def movements
    @movements ||= build_movements
  end

  def comments
    @comments ||= TaskComment
      .where(created_at: period_start...period_end)
      .includes(:user, task: { board: :campaign })
      .order(:created_at)
      .map do |comment|
        Comment.new(
          task: comment.task,
          author_label: comment.author_label,
          occurred_at: comment.created_at,
          excerpt: ActionView::Base.full_sanitizer.sanitize(comment.body).squish.truncate(COMMENT_EXCERPT_LENGTH)
        )
      end
  end

  def empty?
    movements.empty? && comments.empty?
  end

  private

  def build_movements
    activities = TaskActivity
      .where(action: "moved", created_at: period_start...period_end)
      .includes(:user, task: { board: :campaign })
      .order(:created_at)
      .to_a

    column_activities = activities.select { |activity| activity.field_name == "board_column" }
    consumed_column_activity_ids = []
    board_movements = activities.filter_map do |activity|
      next unless activity.field_name == "board"

      column_activity = column_activities.find do |candidate|
        candidate.task_id == activity.task_id &&
          candidate.note.present? &&
          candidate.note == activity.note &&
          (candidate.created_at - activity.created_at).abs < 10.seconds
      end
      consumed_column_activity_ids << column_activity.id if column_activity

      Movement.new(
        task: activity.task,
        actor_label: actor_label(activity),
        occurred_at: activity.created_at,
        from_label: [ activity.old_value, column_activity&.old_value ].compact.join(" · "),
        to_label: [ activity.new_value, column_activity&.new_value ].compact.join(" · ")
      )
    end

    column_movements = column_activities
      .reject { |activity| consumed_column_activity_ids.include?(activity.id) }
      .map do |activity|
        Movement.new(
          task: activity.task,
          actor_label: actor_label(activity),
          occurred_at: activity.created_at,
          from_label: activity.old_value,
          to_label: activity.new_value
        )
      end

    (board_movements + column_movements).sort_by(&:occurred_at)
  end

  def actor_label(activity)
    activity.user&.display_label || activity.actor_name.presence || "Unbekannt"
  end
end
