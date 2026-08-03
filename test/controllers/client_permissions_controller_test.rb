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

  test "client can create and duplicate cards with supported card attributes" do
    assert_difference "Task.count", 1 do
      post board_tasks_path(@board), params: {
        task: {
          name: "Client-Karte",
          board_column_id: @column.id,
          description: "Nicht uebernehmen",
          priority: "high",
          owner: "integration",
          color: "red"
        }
      }
    end

    created_task = Task.unscoped.order(:created_at).last
    assert_redirected_to board_path(@board)
    assert_equal @client, created_task.user
    assert_equal @column, created_task.board_column
    assert_equal "Client-Karte", created_task.name
    assert_equal "Nicht uebernehmen", created_task.description
    assert_equal "none", created_task.priority
    assert_equal "unassigned", created_task.owner
    assert_equal "red", created_task.color

    assert_difference "Task.count", 1 do
      post duplicate_board_task_path(@board, @task)
    end

    copy = Task.unscoped.order(:created_at).last
    assert_redirected_to board_path(@board)
    assert_equal @client, copy.user
    assert_equal "#{@task.name} Kopie", copy.name
    assert_equal @task.board_column, copy.board_column
  end

  test "client can create a card through the inline JSON request" do
    assert_difference "Task.count", 1 do
      post board_tasks_path(@board),
        params: { task: { title: "JSON Client-Karte", board_column_id: @column.id } }.to_json,
        headers: { "CONTENT_TYPE" => "application/json", "ACCEPT" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "client can open the card form but cannot duplicate an archived card" do
    get new_board_task_path(@board)
    assert_response :success

    @task.archive!

    assert_no_difference "Task.count" do
      post duplicate_board_task_path(@board, @task)
    end
    assert_response :not_found
  end

  test "client can fully manage cards and asset lists but cannot change agent state" do
    patch board_task_path(@board, @task), params: {
      task: { name: "Geändert", description: "Neue Beschreibung", board_column_id: @column.id, color: "purple", priority: "high", owner: "integration" }
    }
    assert_redirected_to board_task_path(@board, @task)
    @task.reload
    assert_equal "Geändert", @task.name
    assert_equal "Neue Beschreibung", @task.description
    assert_equal "purple", @task.color
    assert_equal "none", @task.priority
    assert_equal "unassigned", @task.owner

    patch archive_board_task_path(@board, @task)
    assert_redirected_to board_path(@board)
    assert @task.reload.archived_at.present?
    patch restore_board_task_path(@board, @task)
    assert_redirected_to archived_board_tasks_path(@board)
    assert_nil @task.reload.archived_at

    post board_task_subtasks_path(@board, @task), params: { subtask: { title: "Neu" } }
    assert_redirected_to board_task_path(@board, @task)
    subtask = @task.subtasks.find_by!(title: "Neu")
    patch board_task_subtask_path(@board, @task, subtask), params: { subtask: { title: "Umbenannt", done: true } }
    assert_redirected_to board_task_path(@board, @task)
    assert_equal [ "Umbenannt", true ], [ subtask.reload.title, subtask.done? ]
    delete board_task_subtask_path(@board, @task, subtask)
    assert_redirected_to board_task_path(@board, @task)
    assert_not Subtask.exists?(subtask.id)

    patch assign_board_task_path(@board, @task)
    assert_response :not_found
    patch unassign_board_task_path(@board, @task)
    assert_response :not_found
    assert_not @task.assigned_to_agent?

    assert_difference "Task.count", -1 do
      delete board_task_path(@board, @task)
    end
    assert_redirected_to board_path(@board)
  end

  test "client can create text comments" do
    assert_difference "TaskComment.count", 1 do
      post board_task_comments_path(@board, @task), params: { task_comment: { body: "Freigabe geprüft" } }
    end

    assert_redirected_to board_task_path(@board, @task)
    assert_equal @client, TaskComment.order(:created_at).last.user
  end

  test "client can upload valid comment images but cannot change avatars" do
    assert_difference [ "TaskComment.count", "ActiveStorage::Attachment.count" ], 1 do
      post board_task_comments_path(@board, @task),
        params: { task_comment: { body: "Bildfreigabe", images: [ uploaded_png ] } }
    end
    assert_redirected_to board_task_path(@board, @task)

    patch settings_path, params: { user: { avatar: uploaded_png(filename: "avatar.png") } }
    assert_response :not_found
    assert_not @client.reload.avatar.attached?
  end

  test "cover image is not a task feature" do
    assert_nil Task.attachment_reflections["cover_image"]

    patch board_task_path(@board, @task), params: { task: { cover_image: uploaded_png(filename: "cover.png") } }
    assert_redirected_to board_task_path(@board, @task)
  end

  test "client cannot use internal agent web endpoint" do
    post agent_chat_path, params: { message_type: "focus" }

    assert_response :not_found
  end
end
