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

  test "client board view exposes all card actions but not board administration" do
    sign_in_as users(:client)

    get board_path(boards(:one))

    assert_response :success
    assert_match "Karte duplizieren", response.body
    assert_match "Kartenaktionen", response.body
    assert_match "Karte hinzufügen", response.body
    assert_match 'data-sortable-disabled-value="true"', response.body
    assert_match "Karte bearbeiten", response.body
    assert_match "Karte archivieren", response.body
    assert_match "Karte löschen", response.body
    assert_no_match "Spaltenaktionen", response.body
    assert_no_match "Spalte umbenennen", response.body
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
