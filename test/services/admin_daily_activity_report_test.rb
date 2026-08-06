require "test_helper"

class AdminDailyActivityReportTest < ActiveSupport::TestCase
  setup do
    @period_start = Time.utc(2026, 8, 4, 5, 30)
    @period_end = Time.utc(2026, 8, 5, 5, 30)
    @task = tasks(:one)
  end

  test "lists in-board movements with actor and columns" do
    TaskActivity.create!(
      task: @task,
      user: users(:client),
      action: "moved",
      field_name: "board_column",
      old_value: "Produktionsplan",
      new_value: "DREI-Review",
      source: "web",
      created_at: @period_start + 1.hour,
      updated_at: @period_start + 1.hour
    )

    movement = report.movements.sole

    assert_equal @task, movement.task
    assert_equal "Client", movement.actor_label
    assert_equal "Produktionsplan", movement.from_label
    assert_equal "DREI-Review", movement.to_label
  end

  test "combines board and column activity for a cross-board movement" do
    note = "Von Board „Test Board One“ nach „Test Board Two“ verschoben."
    TaskActivity.create!(task: @task, user: users(:client), action: "moved", field_name: "board_column", old_value: "Produktionsplan", new_value: "In Bearbeitung", note: note, created_at: @period_start + 1.hour, updated_at: @period_start + 1.hour)
    TaskActivity.create!(task: @task, user: users(:client), action: "moved", field_name: "board", old_value: "Test Board One", new_value: "Test Board Two", note: note, created_at: @period_start + 1.hour + 1.second, updated_at: @period_start + 1.hour + 1.second)

    movement = report.movements.sole

    assert_equal "Test Board One · Produktionsplan", movement.from_label
    assert_equal "Test Board Two · In Bearbeitung", movement.to_label
  end

  test "lists new comments with a safe excerpt" do
    comment = TaskComment.create!(task: @task, user: users(:client), body: "<strong>Bitte ansehen</strong>")
    comment.update_columns(created_at: @period_start + 1.hour, updated_at: @period_start + 1.hour)

    report_comment = report.comments.sole

    assert_equal @task, report_comment.task
    assert_equal "Client", report_comment.author_label
    assert_equal "Bitte ansehen", report_comment.excerpt
  end

  test "is empty without movements or comments in the report period" do
    assert_predicate report, :empty?
  end

  private

  def report
    @report ||= AdminDailyActivityReport.new(period_start: @period_start, period_end: @period_end)
  end
end
