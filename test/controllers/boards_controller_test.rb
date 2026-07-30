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
    assert_includes response.body, %(data-task-card-url-value="#{board_task_path(boards(:one), tasks(:one))}")
    assert_includes response.body, 'data-dropdown-portal-value="true"'
    assert_includes response.body, 'data-dropdown-target="editPanel" class="hidden'
    assert_includes response.body, 'data-modal-manager-target="modal"'
    assert_includes response.body, 'data-modal-manager-id-param="new-campaign-modal"'
    assert_includes response.body, 'data-action="click->modal-manager#close"'
    assert_includes response.body, 'data-inline-add-target="error"'
    assert_includes response.body, "Bitte einen Kartentitel eingeben."
    assert_includes response.body, "md:w-[320px]"
    assert_includes response.body, "gap-3 overflow-x-hidden overflow-y-auto"
    assert_includes response.body, "padding:16px"
    assert_includes response.body, "font-size:15.5px"
    assert_includes response.body, "-webkit-line-clamp:3"
    assert_includes response.body, %(title="#{ERB::Util.html_escape(long_name)}")
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

  test "internal user atomically moves and orders a task in another column" do
    sign_in_as users(:admin)
    board = boards(:one)
    source = board_columns(:one_backlog)
    target = board_columns(:one_active)
    moved = tasks(:one)
    remaining = board.tasks.create!(
      name: "Bleibt im Eingang",
      user: users(:admin),
      board_column: source,
      position: 2
    )
    existing = board.tasks.create!(
      name: "Bereits aktiv",
      user: users(:admin),
      board_column: target,
      position: 1
    )

    patch update_task_status_board_path(board), params: {
      task_id: moved.id,
      source_column_id: source.id,
      board_column_id: target.id,
      task_ids: [existing.id, moved.id]
    }, as: :json

    assert_response :success
    assert_equal target, moved.reload.board_column
    assert_equal 2, moved.position
    assert_equal "in_progress", moved.status
    assert_equal 1, remaining.reload.position
    assert_equal 1, existing.reload.position
  end

  test "invalid task order rolls back the complete move" do
    sign_in_as users(:admin)
    board = boards(:one)
    source = board_columns(:one_backlog)
    target = board_columns(:one_active)
    moved = tasks(:one)

    patch update_task_status_board_path(board), params: {
      task_id: moved.id,
      source_column_id: source.id,
      board_column_id: target.id,
      task_ids: [moved.id, moved.id]
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal source, moved.reload.board_column
    assert_nil moved.position
    assert_equal "inbox", moved.status
    assert_equal "Ungültige oder veraltete Kartenreihenfolge.", response.parsed_body["error"]
  end

  test "stale source column rejects a competing move" do
    sign_in_as users(:admin)
    board = boards(:one)
    moved = tasks(:one)

    patch update_task_status_board_path(board), params: {
      task_id: moved.id,
      source_column_id: board_columns(:one_active).id,
      board_column_id: board_columns(:one_review).id,
      task_ids: [moved.id]
    }, as: :json

    assert_response :conflict
    assert_equal board_columns(:one_backlog), moved.reload.board_column
    assert_equal "Das Board wurde zwischenzeitlich geändert. Bitte erneut versuchen.", response.parsed_body["error"]
  end
end
