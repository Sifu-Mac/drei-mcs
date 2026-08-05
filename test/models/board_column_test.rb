require "test_helper"
require Rails.root.join("db/migrate/20260731110000_make_finished_the_final_board_column")
require Rails.root.join("db/migrate/20260805000000_rename_standard_board_columns")

class BoardColumnTest < ActiveSupport::TestCase
  test "creates with name kind and position" do
    column = boards(:one).board_columns.create!(name: "Neu", kind: :review)

    assert_equal "Neu", column.name
    assert column.kind_review?
    assert column.position.positive?
  end

  test "name is required" do
    column = boards(:one).board_columns.new(kind: :active)

    assert_not column.valid?
    assert_includes column.errors[:name], "can't be blank"
  end

  test "standard review template keeps approval separate from completion" do
    assert_equal [
      ["Produktionsplan", "backlog"],
      ["In Bearbeitung", "active"],
      ["DREI-Review", "review"],
      ["Korrekturen", "blocked"],
      ["Freigegeben", "review"],
      ["Fertig", "done"]
    ], BoardColumn.standard_review_template
  end

  test "column name migration renames only the standard workflow columns" do
    board = boards(:one)
    board.board_columns.create!(name: "Eingang", kind: :review)
    board.board_columns.create!(name: "Kunden-Review", kind: :active)
    board.board_columns.create!(name: "Änderungen angefordert", kind: :backlog)

    RenameStandardBoardColumns.new.up

    assert_equal "Produktionsplan", board_columns(:one_backlog).reload.name
    assert_equal "DREI-Review", board_columns(:one_review).reload.name
    assert_equal "Korrekturen", board_columns(:one_blocked).reload.name
    assert_equal "Eingang", board.board_columns.find_by!(kind: :review, name: "Eingang").name
    assert_equal "Kunden-Review", board.board_columns.find_by!(kind: :active, name: "Kunden-Review").name
    assert_equal "Änderungen angefordert", board.board_columns.find_by!(kind: :backlog, name: "Änderungen angefordert").name
  end

  test "workflow migration converts an existing finished column into the final state" do
    board = workspaces(:primary).boards.new(user: users(:one), campaign: campaigns(:general), name: "Migrations-Board")
    board.column_template = "skip"
    board.save!
    approved = board.board_columns.create!(name: "Freigegeben", kind: :done)
    existing_finished = board.board_columns.create!(name: "Fertig", kind: :review)
    approved_task = board.tasks.create!(name: "Abgenommen", user: users(:one), board_column: approved)
    finished_task = board.tasks.create!(name: "Abgeschlossen", user: users(:one), board_column: existing_finished)

    MakeFinishedTheFinalBoardColumn.new.up

    assert approved.reload.kind_review?
    assert_equal [false, false, "review"], approved_task.reload.attributes.values_at("completed", "blocked", "status")
    assert existing_finished.reload.kind_done?
    assert_equal [true, false, "done"], finished_task.reload.attributes.values_at("completed", "blocked", "status")
    assert_equal 1, board.board_columns.where(name: "Fertig").count
  end

  test "moves left and right" do
    column = board_columns(:one_active)
    original_position = column.position

    column.move_left!
    assert_equal original_position - 1, column.position

    column.move_right!
    assert_equal original_position, column.position
  end

  test "changing kind synchronizes all task state mirrors" do
    column = board_columns(:one_backlog)
    task = tasks(:one)
    archived_task = task.dup
    archived_task.name = "Archived task"
    archived_task.archived_at = Time.current
    archived_task.save!

    column.update!(kind: :blocked)

    [task, archived_task].each do |changed_task|
      changed_task.reload
      assert_equal "blocked", changed_task.status
      assert changed_task.blocked
      assert_not changed_task.completed
      assert_nil changed_task.completed_at
    end

    previous_completed_at = 2.days.ago.change(usec: 0)
    archived_task.update_column(:completed_at, previous_completed_at)
    column.update!(kind: :done)

    completed_at = task.reload.completed_at
    assert_equal "done", task.status
    assert task.completed
    assert_not task.blocked
    assert completed_at.present?
    assert_equal previous_completed_at, archived_task.reload.completed_at

    column.update!(name: "Still done")
    assert_equal completed_at, task.reload.completed_at

    column.update!(kind: :review)
    task.reload
    assert_equal "review", task.status
    assert_not task.completed
    assert_not task.blocked
    assert_nil task.completed_at
  end

  test "kind change rolls back column and synchronized tasks when one task is invalid" do
    column = board_columns(:one_backlog)
    valid_task = tasks(:one)
    invalid_task = valid_task.dup
    invalid_task.name = "Will become invalid"
    invalid_task.save!
    invalid_task.update_column(:name, nil)

    assert_not column.update(kind: :done)
    assert_match "Kartenstatus konnte nicht synchronisiert werden", column.errors.full_messages.join(", ")
    assert column.reload.kind_backlog?
    valid_task.reload
    assert_equal "inbox", valid_task.status
    assert_not valid_task.completed
    assert_nil valid_task.completed_at
  end
end
