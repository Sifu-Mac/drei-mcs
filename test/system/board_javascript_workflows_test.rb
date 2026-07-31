require "application_system_test_case"

class BoardJavascriptWorkflowsTest < ApplicationSystemTestCase
  test "task panel auto-save persists typed changes" do
    task = tasks(:one)
    sign_in_through_browser(users(:one))
    open_task_panel(task)

    title = "Automatisch gespeichert #{SecureRandom.hex(4)}"
    fill_in "task_name", with: title

    assert_selector "[data-task-modal-target='saveStatus']", text: "Gespeichert"
    assert_equal title, task.reload.name
  end

  test "client panel hides mutation controls and still allows comments" do
    task = tasks(:one)
    sign_in_through_browser(users(:client))
    open_task_panel(task)

    assert_no_field "task_name"
    assert_no_field "task_description"
    assert_no_selector "input[type='file'][name='task[cover_image]']"
    assert_no_selector "[data-action='click->task-modal#cyclePriority']"
    assert_no_selector "[data-action='click->task-modal#toggleAgent']"
    assert_no_selector "[data-action='click->task-modal#deleteTask']"

    comment = "Client-Kommentar #{SecureRandom.hex(4)}"
    fill_in "Write a comment...", with: comment
    click_button "Post comment"

    assert_text comment
    assert_equal comment, task.comments.order(:created_at).last.body
  end

  test "drag and drop restores the board and shows an alert after a fetch failure" do
    task = tasks(:one)
    source_column = board_columns(:one_backlog)
    target_column = board_columns(:one_active)
    sign_in_through_browser(users(:one))
    visit board_path(task.board)

    assert_selector "#column-#{source_column.id} #task_#{task.id}"

    page.execute_script <<~JS
      (() => {
        const item = document.getElementById("task_#{task.id}")
        const source = document.getElementById("column-#{source_column.id}")
        const target = document.getElementById("column-#{target_column.id}")
        const controller = target.sortableController
        const originalFetch = window.fetch

        item.sortableSnapshot = controller.captureBoardState()
        target.appendChild(item)
        item.dataset.taskColumnId = "#{target_column.id}"
        window.fetch = () => Promise.reject(new Error("Netzwerk offline"))

        controller.persistMove({ item }, {
          task_id: "#{task.id}",
          board_column_id: "#{target_column.id}",
          source_column_id: "#{source_column.id}",
          task_ids: controller.taskIds(target)
        }).finally(() => {
          window.fetch = originalFetch
        })
      })()
    JS

    assert_selector "[role='alert']", text: "Netzwerk offline"
    assert_selector "#column-#{source_column.id} #task_#{task.id}"
    assert_no_selector "#column-#{target_column.id} #task_#{task.id}"
    assert_equal source_column, task.reload.board_column
  end

  test "active tag filter disables drag and drop and explains why" do
    task = tasks(:one)
    task.update!(tags: ["review"])
    sign_in_through_browser(users(:one))

    visit board_path(task.board, tag: "review")

    assert_text "Karten können mit aktivem Filter nicht verschoben werden."
    assert_selector "#task_#{task.id}"
    assert page.evaluate_script(<<~JS)
      (() => {
        const column = document.getElementById("column-#{task.board_column_id}")
        return column.dataset.sortableDisabledValue === "true" &&
          column.sortableController.sortable.option("disabled") === true
      })()
    JS
  end

  test "unfiltered board keeps drag and drop enabled" do
    task = tasks(:one)
    sign_in_through_browser(users(:one))

    visit board_path(task.board)

    assert_selector "#task_#{task.id}"
    assert page.evaluate_script(<<~JS)
      (() => {
        const column = document.getElementById("column-#{task.board_column_id}")
        return column.dataset.sortableDisabledValue === "false" &&
          column.sortableController.sortable.option("disabled") === false
      })()
    JS
  end
end
