require "test_helper"

class BoardTest < ActiveSupport::TestCase
  test "belongs to campaign" do
    assert_equal campaigns(:general), boards(:one).campaign
  end

  test "archive hides board from active scope and restore shows it again" do
    board = boards(:one)

    board.archive!
    assert board.archived?
    assert_not_includes Board.active, board

    board.restore!
    assert_not board.archived?
    assert_includes Board.active, board
  end

  test "duplicate copies cards into copied board without comments or uploads" do
    board = boards(:one)
    source_task = board.tasks.first
    source_task.subtasks.create!(title: "300x250", position: 1, done: true)
    source_task.subtasks.create!(title: "728x90", position: 2, done: false)

    copy = board.duplicate_to!(campaign: campaigns(:general), user: users(:admin))

    assert_equal "#{board.name} Kopie", copy.name
    assert_equal board.tasks.count, copy.tasks.count
    assert_equal copy.id, copy.tasks.first.board_id
    assert_empty copy.tasks.first.comments
    assert_empty copy.tasks.first.activities
    copied_task = copy.tasks.find_by!(name: source_task.name)
    assert_equal [ "300x250", "728x90" ], copied_task.subtasks.order(:position).pluck(:title)
    assert_equal [ false, false ], copied_task.subtasks.order(:position).pluck(:done)
  end
end
