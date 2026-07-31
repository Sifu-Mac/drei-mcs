require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  test "admin can explicitly create another admin" do
    sign_in_as users(:admin)

    assert_difference("User.count", 1) do
      post admin_users_path, params: {
        user: {
          email_address: "new-admin@example.com",
          password: "password123",
          password_confirmation: "password123",
          admin: "1"
        }
      }
    end

    assert_redirected_to admin_users_path
    assert_predicate User.find_by!(email_address: "new-admin@example.com"), :admin?
  end

  test "admin creates a regular user when admin is not selected" do
    sign_in_as users(:admin)

    assert_difference("User.count", 1) do
      post admin_users_path, params: {
        user: {
          email_address: "new-member@example.com",
          password: "password123",
          password_confirmation: "password123",
          admin: "0"
        }
      }
    end

    assert_redirected_to admin_users_path
    assert_not User.find_by!(email_address: "new-member@example.com").admin?
  end
end
