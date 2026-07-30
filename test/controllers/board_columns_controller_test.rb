require "test_helper"

class BoardColumnsControllerTest < ActionDispatch::IntegrationTest
  test "internal user creates column" do
    sign_in_as users(:admin)

    assert_difference "BoardColumn.count", 1 do
      post board_board_columns_path(boards(:one)), params: { board_column: { name: "Final", kind: "done" } }
    end

    assert_redirected_to board_path(boards(:one))
  end

  test "internal user renames and changes kind" do
    sign_in_as users(:admin)

    patch board_board_column_path(boards(:one), board_columns(:one_review)), params: { board_column: { name: "Prüfung intern", kind: "review" } }

    assert_redirected_to board_path(boards(:one))
    assert_equal "Prüfung intern", board_columns(:one_review).reload.name
  end

  test "empty column can be deleted" do
    sign_in_as users(:admin)
    column = boards(:one).board_columns.create!(name: "Leer", kind: :backlog)

    assert_difference "BoardColumn.count", -1 do
      delete board_board_column_path(boards(:one), column)
    end

    assert_redirected_to board_path(boards(:one))
  end

  test "column with cards cannot be deleted" do
    sign_in_as users(:admin)

    assert_no_difference "BoardColumn.count" do
      delete board_board_column_path(boards(:one), board_columns(:one_backlog))
    end

    assert_redirected_to board_path(boards(:one))
    assert_equal "Diese Spalte enthält noch Karten und kann nicht gelöscht werden.", flash[:alert]
  end

  test "client cannot mutate columns" do
    sign_in_as users(:client)

    assert_no_difference "BoardColumn.count" do
      post board_board_columns_path(boards(:one)), params: { board_column: { name: "Client", kind: "active" } }
    end

    assert_response :not_found
  end
end
