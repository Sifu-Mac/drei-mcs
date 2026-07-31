require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |options|
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
  end

  private

  def sign_in_through_browser(user)
    visit new_session_path
    fill_in "Email", with: user.email_address
    fill_in "Password", with: "password123"
    click_button "Sign in"
    assert_current_path %r{/boards/\d+}
  end

  def open_task_panel(task)
    visit board_path(task.board)
    find("#task_#{task.id}").click
    assert_selector "#task_panel [data-controller~='task-modal']"
  end
end
