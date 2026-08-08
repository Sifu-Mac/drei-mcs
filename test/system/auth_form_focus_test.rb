require "application_system_test_case"

class AuthFormFocusTest < ApplicationSystemTestCase
  test "login keeps focus on its field container instead of the input" do
    visit new_session_path

    email_input = find("input[name='email_address']")
    email_input.click

    assert_equal "none", page.evaluate_script("getComputedStyle(document.querySelector(\"input[name='email_address']\")).outlineStyle")
    assert email_input.find(:xpath, "..")["class"].include?("focus-within:ring-border-accent")
  end

  test "password reset forms use the same input focus treatment" do
    visit new_password_path

    assert_equal "none", page.evaluate_script("getComputedStyle(document.querySelector(\"input[name='email_address']\")).outlineStyle")
    assert_selector ".auth-field input.auth-field-input", count: 1

    visit edit_password_path(users(:one).password_reset_token)

    assert_selector ".auth-field input.auth-field-input", count: 2
  end
end
