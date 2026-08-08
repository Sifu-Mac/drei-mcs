require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  test "new renders the single-field auth focus treatment" do
    get new_password_path

    assert_response :success
    assert_select ".auth-field", count: 1
    assert_select "input.auth-field-input", count: 1
  end

  test "edit renders the password auth focus treatment" do
    get edit_password_path(users(:one).password_reset_token)

    assert_response :success
    assert_select ".auth-field", count: 2
    assert_select "input.auth-field-input", count: 2
  end
end
