require "test_helper"

class BoardsTasksControllerTest < ActionDispatch::IntegrationTest
  test "internal user duplicates card without comments uploads or activities" do
    sign_in_as users(:admin)
    task = tasks(:one)

    assert_difference "Task.count", 1 do
      post duplicate_board_task_path(boards(:one), task)
    end

    copy = Task.unscoped.order(:created_at).last
    assert_equal "#{task.name} Kopie", copy.name
    assert_equal task.board_column_id, copy.board_column_id
    assert_equal task.color, copy.color
    assert_empty copy.comments
    assert_empty copy.activities
    assert_redirected_to board_path(boards(:one))
  end

  test "internal user duplicates card with turbo stream board update" do
    sign_in_as users(:admin)
    task = tasks(:one)

    assert_difference "Task.count", 1 do
      post duplicate_board_task_path(boards(:one), task),
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    copy = Task.unscoped.order(:created_at).last
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, "column-#{copy.board_column_id}"
    assert_includes response.body, "task_#{copy.id}"
    assert_includes response.body, 'target="task_panel"'
    assert_includes response.body, "#{task.name} Kopie"
  end

  test "internal user archives and restores card" do
    sign_in_as users(:admin)
    task = tasks(:one)

    patch archive_board_task_path(boards(:one), task)
    assert task.reload.archived_at.present?

    patch restore_board_task_path(boards(:one), task)
    assert_nil task.reload.archived_at
  end

  test "task panel renders in turbo frame" do
    sign_in_as users(:admin)

    get board_task_path(boards(:one), tasks(:one)), headers: { "Turbo-Frame" => "task_panel" }

    assert_response :success
    assert_includes response.body, 'id="task_panel"'
    assert_includes response.body, tasks(:one).board_column.name
    assert_equal 3, response.body.scan(/(?:input|change)-&gt;task-modal#scheduleAutoSave/).size
    assert_not_includes response.body, "click->task-modal#cyclePriority"
    assert_not_includes response.body, "scheduleAutoSpeichern"
    assert_includes response.body, 'role="status"'
    assert_includes response.body, "Klicken zum Bearbeiten"
  end

  test "auto-save update persists supported card panel fields" do
    sign_in_as users(:admin)
    task = tasks(:one)

    patch board_task_path(boards(:one), task),
          params: {
            task: {
              name: "Auto-Save Titel",
              description: "Auto-Save Beschreibung",
              priority: "high",
              owner: "integration",
              color: "purple"
            }
          },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    task.reload
    assert_equal "Auto-Save Titel", task.name
    assert_equal "Auto-Save Beschreibung", task.description
    assert_equal "none", task.priority
    assert_equal "unassigned", task.owner
    assert_equal "purple", task.color
  end

  test "client can duplicate card" do
    sign_in_as users(:client)

    assert_difference "Task.count", 1 do
      post duplicate_board_task_path(boards(:one), tasks(:one))
    end

    copy = Task.unscoped.order(:created_at).last
    assert_redirected_to board_path(boards(:one))
    assert_equal users(:client), copy.user
    assert_equal "#{tasks(:one).name} Kopie", copy.name
  end

  test "client can copy and move a card to another active board in the workspace" do
    sign_in_as users(:client)
    target = Board.create!(user: users(:admin), workspace: workspaces(:primary), campaign: campaigns(:general), name: "Transferziel", icon: "📋", color: "blue", column_template: "simple")
    target_column = target.board_columns.first
    task = tasks(:one)
    task.subtasks.create!(title: "16:9", done: true)

    get transfer_board_task_path(boards(:one), task, mode: "copy")
    assert_response :success
    assert_includes response.body, "Zielboard und Zielspalte"

    assert_difference "Task.count", 1 do
      post copy_to_board_board_task_path(boards(:one), task), params: { transfer: { destination: "#{target.id}:#{target_column.id}" } }
    end
    copy = Task.unscoped.order(:created_at).last
    assert_redirected_to board_task_path(target, copy)
    assert_equal [ [ "16:9", true ] ], copy.subtasks.pluck(:title, :done)

    patch move_to_board_board_task_path(boards(:one), task), params: { transfer: { destination: "#{target.id}:#{target_column.id}" } }
    assert_redirected_to board_task_path(target, task)
    assert_equal [ target.id, target_column.id ], task.reload.attributes.values_at("board_id", "board_column_id")
  end

  test "client board view exposes all card actions but not board administration" do
    sign_in_as users(:client)

    get board_path(boards(:one))

    assert_response :success
    assert_match "Karte duplizieren", response.body
    assert_match "Kartenaktionen", response.body
    assert_match "Karte hinzufügen", response.body
    assert_match 'data-sortable-disabled-value="true"', response.body
    assert_match "Karte bearbeiten", response.body
    assert_match "In anderes Board kopieren", response.body
    assert_match "In anderes Board verschieben", response.body
    assert_match "Karte archivieren", response.body
    assert_match "Karte löschen", response.body
    assert_no_match "Spaltenaktionen", response.body
    assert_no_match "Spalte umbenennen", response.body
  end

  test "card transfer rejects a board outside the current workspace" do
    sign_in_as users(:client)
    task = tasks(:one)

    assert_no_difference "Task.count" do
      post copy_to_board_board_task_path(boards(:one), task), params: { transfer: { destination: "#{boards(:two).id}:#{board_columns(:two_backlog).id}" } }
    end

    assert_response :not_found
  end

  test "card transfer asks for a destination instead of mutating when none was selected" do
    sign_in_as users(:client)

    assert_no_difference "Task.count" do
      post copy_to_board_board_task_path(boards(:one), tasks(:one)), params: { transfer: { destination: "" } }
    end

    assert_redirected_to transfer_board_task_path(boards(:one), tasks(:one), mode: "copy")
    assert_includes flash[:alert], "Zielboard und Zielspalte"
  end

  test "client task panel includes all card controls except agent controls" do
    sign_in_as users(:client)
    task = tasks(:one)
    task.subtasks.create!(title: "Nur lesen")

    get board_task_path(boards(:one), task), headers: { "Turbo-Frame" => "task_panel" }

    assert_response :success
    assert_includes response.body, task.name
    assert_includes response.body, "Nur lesen"
    assert_includes response.body, "Kommentar"
    assert_includes response.body, board_task_comments_path(boards(:one), task)
    assert_includes response.body, "data-task-modal-update-url-value"
    assert_not_includes response.body, "data-task-modal-assign-url-value"
    assert_not_includes response.body, "data-task-modal-unassign-url-value"
    assert_includes response.body, "data-task-modal-delete-url-value"
    assert_includes response.body, 'name="task[name]"'
    assert_includes response.body, "Spalte"
    assert_not_includes response.body, 'name="task[priority]"'
    assert_includes response.body, 'name="task[color]"'
    assert_not_includes response.body, 'name="task[owner]"'
    assert_includes response.body, board_task_subtask_path(boards(:one), task, task.subtasks.first)
    assert_not_includes response.body, "click-&gt;task-modal#toggleAgent"
    assert_includes response.body, "click->task-modal#deleteTask"
    assert_includes response.body, "Klicken zum Bearbeiten"
    assert_not_includes response.body, "Activity"
  end
end
