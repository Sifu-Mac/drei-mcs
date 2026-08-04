require "test_helper"
class TaskTest < ActiveSupport::TestCase
  setup do
    @task = tasks(:one)
  end

  test "task has no cover image attachment" do
    assert_nil Task.attachment_reflections["cover_image"]
  end

  test "duplicate copies asset list titles but resets completion" do
    @task.subtasks.create!(title: "1:1", done: true)
    @task.subtasks.create!(title: "9:16", done: false)
    @task.update!(assigned_to_agent: true, assigned_at: Time.current, agent_claimed_at: Time.current)

    copy = @task.duplicate_for!(user: users(:admin))

    assert_equal [ "1:1", "9:16" ], copy.subtasks.pluck(:title)
    assert_equal [ false, false ], copy.subtasks.pluck(:done)
    assert_not copy.assigned_to_agent?
    assert_nil copy.assigned_at
    assert_nil copy.agent_claimed_at
  end

  test "copying to another board preserves card contents, checklist, comments, quotes and images" do
    target = transfer_target_board
    target_column = target.board_columns.first
    @task.update!(description: "Vollständige Beschreibung", color: "purple", tags: [ "video", "social" ])
    @task.subtasks.create!(title: "16:9", position: 1, done: true)
    @task.subtasks.create!(title: "9:16", position: 2, done: false)
    original = @task.comments.create!(user: users(:admin), body: "Ausgangskommentar")
    attach_png(original.images, filename: "review.png")
    reply = @task.comments.create!(user: users(:client), body: "Antwort", quoted_comment: original)

    copy = @task.copy_to_board!(board: target, board_column: target_column, user: users(:client))

    assert_equal "#{@task.name} Kopie", copy.name
    assert_equal [ "Vollständige Beschreibung", "purple", [ "video", "social" ] ], [ copy.description, copy.color, copy.tags ]
    assert_equal [ [ "16:9", true ], [ "9:16", false ] ], copy.subtasks.order(:position).pluck(:title, :done)
    assert_equal @task.comments.count, copy.comments.count
    copied_original = copy.comments.find_by!(body: "Ausgangskommentar")
    copied_reply = copy.comments.find_by!(body: "Antwort")
    assert copied_original.images.attached?
    assert_equal copied_original.id, copied_reply.quoted_comment_id
    assert_equal original.created_at.to_i, copied_original.created_at.to_i
    assert_equal "Kopie aus Board „#{@task.board.name}“.", copy.activities.last.note
  end

  test "moving to another board keeps the same card and all associated content" do
    target = transfer_target_board
    target_column = target.board_columns.first
    @task.subtasks.create!(title: "1:1", done: true)
    @task.comments.create!(user: users(:admin), body: "Bleibt erhalten")
    original_id = @task.id

    moved = @task.move_to_board!(board: target, board_column: target_column, user: users(:client))

    assert_equal original_id, moved.id
    assert_equal [ target, target_column ], [ moved.board, moved.board_column ]
    assert_equal [ [ "1:1", true ] ], moved.subtasks.pluck(:title, :done)
    assert_equal "Bleibt erhalten", moved.comments.last.body
    movement = moved.activities.where(field_name: "board").last
    assert_equal [ boards(:one).name, target.name ], [ movement.old_value, movement.new_value ]
  end

  test "completion and blocked state follow board column kind" do
    task = tasks(:one)

    task.update!(board_column: board_columns(:one_done))
    assert task.completed?
    assert task.completed_at.present?
    assert_equal "done", task.status

    task.update!(board_column: board_columns(:one_blocked))
    assert task.blocked?
    assert_not task.completed?
    assert_nil task.completed_at
    assert_equal "blocked", task.status
  end

  test "color accepts allowed values" do
    Task::COLOR_VALUES.each do |color|
      @task.color = color
      assert @task.valid?, "#{color} should be valid"
    end
  end

  test "color rejects invalid values" do
    @task.color = "magenta"

    assert_not @task.valid?
  end

  private

  def transfer_target_board
    Board.create!(
      user: users(:admin), workspace: workspaces(:primary), campaign: campaigns(:general),
      name: "Transferziel", icon: "📋", color: "blue", column_template: "simple"
    )
  end
end
