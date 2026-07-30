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

    copy = board.duplicate_to!(campaign: campaigns(:general), user: users(:admin))

    assert_equal "#{board.name} Kopie", copy.name
    assert_equal board.tasks.count, copy.tasks.count
    assert_equal copy.id, copy.tasks.first.board_id
    assert_empty copy.tasks.first.comments
    assert_not copy.tasks.first.cover_image.attached?
    assert_empty copy.tasks.first.activities
  end
end
