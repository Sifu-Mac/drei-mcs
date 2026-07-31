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

    copy = @task.duplicate_for!(user: users(:admin))

    assert_equal [ "1:1", "9:16" ], copy.subtasks.pluck(:title)
    assert_equal [ false, false ], copy.subtasks.pluck(:done)
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
end
