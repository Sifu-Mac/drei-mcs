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

  test "duplicate board copies columns and keeps copied cards in copied columns" do
    sign_in_as users(:admin)

    post duplicate_board_path(boards(:one))
    copy = Board.order(:created_at).last

    assert_equal boards(:one).board_columns.count, copy.board_columns.count
    assert_equal copy.board_columns.first.id, copy.tasks.first.board_column_id
  end

  test "board view renders spacious interactive card and column contracts" do
    sign_in_as users(:admin)
    long_name = "Sehr langer Spaltenname fuer Asset Review und finale Freigabe"
    board_columns(:one_backlog).update!(name: long_name)

    get board_path(boards(:one))

    assert_response :success
    assert_includes response.body, 'data-controller="task-card"'
    assert_includes response.body, "data-task-card-url-value="#{board_task_path(boards(:one), tasks(:one))}""
    assert_includes response.body, 'data-dropdown-portal-value="true"'
    assert_includes response.body, 'data-dropdown-target="editPanel" class="hidden'
    assert_includes response.body, 'md:w-[320px]'
    assert_includes response.body, 'gap-3 overflow-x-hidden overflow-y-auto'
    assert_includes response.body, 'padding:16px'
    assert_includes response.body, 'font-size:15.5px'
    assert_includes response.body, '-webkit-line-clamp:3'
    assert_includes response.body, "title="#{ERB::Util.html_escape(long_name)}""
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
