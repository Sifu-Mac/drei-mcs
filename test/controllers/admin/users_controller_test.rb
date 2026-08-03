require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  test "admin can promote and demote a client" do
    sign_in_as users(:admin)
    client = users(:client)

    assert_difference "AuditEvent.count", 1 do
      patch promote_admin_user_path(client)
    end
    assert_predicate client.reload, :admin?

    assert_difference "AuditEvent.count", 1 do
      patch demote_admin_user_path(client)
    end
    assert_not client.reload.admin?
  end

  test "last admin and current admin cannot be demoted" do
    sign_in_as users(:admin)

    patch demote_admin_user_path(users(:admin))
    assert_redirected_to admin_users_path
    assert_predicate users(:admin).reload, :admin?
  end

  test "client cannot manage user rights" do
    sign_in_as users(:client)

    patch promote_admin_user_path(users(:one))
    assert_response :not_found
  end

  test "admin can delete a client with card history while preserving the activity" do
    admin = users(:admin)
    client = users(:client)
    activity = TaskActivity.create!(task: tasks(:one), user: client, action: "updated")
    sign_in_as admin

    assert_difference "User.count", -1 do
      delete admin_user_path(client)
    end

    assert_redirected_to admin_users_path
    assert_nil activity.reload.user_id
    assert_equal tasks(:one), activity.task
  end
end
