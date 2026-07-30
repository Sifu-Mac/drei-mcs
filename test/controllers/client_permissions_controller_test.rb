require "test_helper"

class ClientPermissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @client = users(:client)
    @board = boards(:one)
    @task = tasks(:one)
    @campaign = campaigns(:general)
    @column = board_columns(:one_backlog)
    @subtask = @task.subtasks.create!(title: "Geschützt")
    sign_in_as @client
  end

  test "client cannot mutate campaigns through any endpoint" do
    original_name = @campaign.name

    post campaigns_path, params: { campaign: { name: "Neu" } }
    assert_response :not_found
    patch campaign_path(@campaign), params: { campaign: { name: "Geändert" } }
    assert_response :not_found
    post duplicate_campaign_path(@campaign)
    assert_response :not_found
    patch archive_campaign_path(@campaign)
    assert_response :not_found
    patch restore_campaign_path(@campaign)
    assert_response :not_found

    assert_equal original_name, @campaign.reload.name
    assert_not @campaign.archived?
  end

  test "client cannot mutate boards or columns through any endpoint" do
    original_board_name = @board.name
    original_column_name = @column.name

    post boards_path, params: { board: { name: "Neu", campaign_id: @campaign.id } }
    assert_response :not_found
    patch board_path(@board), params: { board: { name: "Geändert" } }
    assert_response :not_found
    post duplicate_board_path(@board)
    assert_response :not_found
    patch archive_board_path(@board)
    assert_response :not_found
    delete board_path(@board)
    assert_response :not_found
    patch update_task_status_board_path(@board), params: { task_id: @task.id, board_column_id: @column.id }
    assert_response :not_found

    post board_board_columns_path(@board), params: { board_column: { name: "Neu", kind: "active" } }
    assert_response :not_found
    patch board_board_column_path(@board, @column), params: { board_column: { name: "Geändert" } }
    assert_response :not_found
    patch move_left_board_board_column_path(@board, @column)
    assert_response :not_found
    patch move_right_board_board_column_path(@board, @column)
    assert_response :not_found
    delete board_board_column_path(@board, @column)
    assert_response :not_found

    assert_equal original_board_name, @board.reload.name
    assert_equal original_column_name, @column.reload.name
  end

  test "client cannot mutate tasks subtasks or agent assignment" do
    original_name = @task.name

    post board_tasks_path(@board), params: { task: { name: "Neu" } }
    assert_response :not_found
    patch board_task_path(@board, @task), params: { task: { name: "Geändert" } }
    assert_response :not_found
    post duplicate_board_task_path(@board, @task)
    assert_response :not_found
    patch archive_board_task_path(@board, @task)
    assert_response :not_found
    patch restore_board_task_path(@board, @task)
    assert_response :not_found
    patch assign_board_task_path(@board, @task)
    assert_response :not_found
    patch unassign_board_task_path(@board, @task)
    assert_response :not_found
    delete board_task_path(@board, @task)
    assert_response :not_found

    post board_task_subtasks_path(@board, @task), params: { subtask: { title: "Neu" } }
    assert_response :not_found
    patch board_task_subtask_path(@board, @task, @subtask), params: { subtask: { done: true } }
    assert_response :not_found
    delete board_task_subtask_path(@board, @task, @subtask)
    assert_response :not_found

    assert_equal original_name, @task.reload.name
    assert_not @task.assigned_to_agent?
    assert_not @subtask.reload.done?
  end

  test "client can create text comments" do
    assert_difference "TaskComment.count", 1 do
      post board_task_comments_path(@board, @task), params: { task_comment: { body: "Freigabe geprüft" } }
    end

    assert_redirected_to board_task_path(@board, @task)
    assert_equal @client, TaskComment.order(:created_at).last.user
  end

  test "client cannot use internal agent web endpoint" do
    post agent_chat_path, params: { message_type: "focus" }

    assert_response :not_found
  end
end
