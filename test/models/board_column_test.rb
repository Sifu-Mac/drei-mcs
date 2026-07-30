require "test_helper"

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

  test "moves left and right" do
    column = board_columns(:one_active)
    original_position = column.position

    column.move_left!
    assert_equal original_position - 1, column.position

    column.move_right!
    assert_equal original_position, column.position
  end
end
