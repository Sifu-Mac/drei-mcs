require "application_system_test_case"

class BoardJavascriptWorkflowsTest < ApplicationSystemTestCase
  test "task panel auto-save persists typed changes" do
    task = tasks(:one)
    sign_in_through_browser(users(:admin))
    open_task_panel(task)

    title = "Automatisch gespeichert #{SecureRandom.hex(4)}"
    title_field = find("#task_name")
    title_field.click
    assert_not page.evaluate_script("document.getElementById('task_name').readOnly")
    title_field.send_keys([ :control, "a" ], title)

    assert_selector "[data-task-modal-target='saveStatus']", text: "Gespeichert"
    assert_equal title, task.reload.name
  end

  test "client panel allows card edits and comments but hides agent controls" do
    task = tasks(:one)
    sign_in_through_browser(users(:client))
    open_task_panel(task)

    assert_field "task_name"
    assert_field "task_description"
    assert_no_selector "input[type='file'][name='task[cover_image]']"
    assert_no_selector "[data-action='click->task-modal#cyclePriority']"
    assert_no_selector "[data-action='click->task-modal#toggleAgent']"
    assert_selector "[data-action='click->task-modal#deleteTask']"

    title = "Client-Titel #{SecureRandom.hex(4)}"
    title_field = find("#task_name")
    title_field.click
    assert_not page.evaluate_script("document.getElementById('task_name').readOnly")
    title_field.send_keys([ :control, "a" ], title)
    assert_selector "[data-task-modal-target='saveStatus']", text: "Gespeichert"
    assert_equal title, task.reload.name

    comment = "Client-Kommentar #{SecureRandom.hex(4)}"
    fill_in "Write a comment...", with: comment
    click_button "Post comment"

    assert_text comment
    assert_equal comment, task.comments.order(:created_at).last.body
  end

  test "client can add and duplicate cards but cannot drag them" do
    task = tasks(:one)
    sign_in_through_browser(users(:client))
    visit board_path(task.board)

    title = "Client-Karte #{SecureRandom.hex(4)}"
    click_button "Karte hinzufügen", match: :first
    find("textarea[data-inline-add-target='input']").fill_in with: title
    find("button[data-inline-add-target='submit']").click

    assert_text title
    created_task = Task.unscoped.order(:created_at).last
    assert_equal users(:client), created_task.user

    find("#task_#{task.id} [aria-label='Kartenaktionen']").click
    click_button "Karte duplizieren"

    assert_text "#{task.name} Kopie"
    copy = Task.unscoped.order(:created_at).last
    assert_equal users(:client), copy.user
    assert page.evaluate_script("document.getElementById('column-#{task.board_column_id}').sortableController.sortable.option('disabled')")
  end

  test "drag and drop restores the board and shows an alert after a fetch failure" do
    task = tasks(:one)
    source_column = board_columns(:one_backlog)
    target_column = board_columns(:one_active)
    sign_in_through_browser(users(:admin))
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
    sign_in_through_browser(users(:admin))

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
    sign_in_through_browser(users(:admin))

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

  test "card creation action follows the cards instead of the viewport bottom" do
    task = tasks(:one)
    sign_in_through_browser(users(:admin))

    visit board_path(task.board)

    assert page.evaluate_script(<<~JS)
      (() => {
        const column = document.getElementById("board-column-#{task.board_column_id}")
        const cards = column.querySelector("ul")
        const addAction = column.querySelector("[data-inline-add-target='button']")
        const gap = addAction.getBoundingClientRect().top - cards.getBoundingClientRect().bottom
        return getComputedStyle(cards).flexGrow === "0" && gap >= 0 && gap <= 16
      })()
    JS
  end

  test "sidebar menus close each other and can be dismissed with Escape" do
    task = tasks(:one)
    sign_in_through_browser(users(:admin))
    visit board_path(task.board)

    find("button[aria-label='Kampagnenaktionen']").click
    assert_equal 1, visible_dropdown_menu_count

    find("button[aria-label='Boardaktionen']").click
    assert_equal 1, visible_dropdown_menu_count

    page.execute_script("document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }))")
    assert_equal 0, visible_dropdown_menu_count

    click_button "Board hinzufügen"
    assert_selector "input[placeholder='Boardname']"

    page.execute_script("document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }))")
    assert_no_selector "input[placeholder='Boardname']", visible: true
  end

  private

  def visible_dropdown_menu_count
    page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll("[data-dropdown-target='menu']"))
        .filter((menu) => !menu.classList.contains("hidden")).length
    JS
  end
end
