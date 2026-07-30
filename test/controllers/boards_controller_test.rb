require "test_helper"

class BoardsControllerTest < ActionDispatch::IntegrationTest
  test "internal user creates board inside campaign" do
    sign_in_as users(:admin)

    assert_difference "Board.count", 1 do
      post boards_path, params: { board: { name: "Assets", campaign_id: campaigns(:general).id, icon: "📋" } }
    end

    assert_redirected_to board_path(Board.order(:created_at).last)
    assert_equal campaigns(:general), Board.order(:created_at).last.campaign
  end

  test "internal user renames board" do
    sign_in_as users(:admin)

    patch board_path(boards(:one)), params: { board: { name: "Umbenannt" } }

    assert_redirected_to board_path(boards(:one))
    assert_equal "Umbenannt", boards(:one).reload.name
  end

  test "internal user archives board instead of deleting it" do
    sign_in_as users(:admin)
    boards(:one).campaign.boards.create!(workspace: workspaces(:primary), user: users(:admin), name: "Zweites Board")

    assert_no_difference "Board.unscoped.count" do
      patch archive_board_path(boards(:one))
    end

    assert_redirected_to boards_path
    assert boards(:one).reload.archived?
  end

  test "internal user duplicates board with cards" do
    sign_in_as users(:admin)

    assert_difference ["Board.count", "Task.count"], 1 do
      post duplicate_board_path(boards(:one))
    end

    assert_redirected_to board_path(Board.order(:created_at).last)
  end

  test "client can see board but cannot mutate board structure" do
    sign_in_as users(:client)

    get board_path(boards(:one))
    assert_response :success

    assert_no_difference "Board.count" do
      post boards_path, params: { board: { name: "Client Board", campaign_id: campaigns(:general).id } }
    end

    assert_response :not_found
  end
end
