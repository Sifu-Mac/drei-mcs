require "test_helper"

class PasswordChangesControllerTest < ActionDispatch::IntegrationTest
  test "user changes their password and other sessions are removed" do
    user = users(:admin)
    sign_in_as user
    other_session = user.sessions.create!(user_agent: "test", ip_address: "127.0.0.1")

    assert_difference "AuditEvent.count", 1 do
      patch password_change_path, params: { user: { current_password: "password123", password: "new-password-123", password_confirmation: "new-password-123" } }
    end

    assert_redirected_to settings_path
    assert user.reload.authenticate("new-password-123")
    assert_not Session.exists?(other_session.id)
  end

  test "password change requires the current password" do
    sign_in_as users(:client)

    assert_no_difference "AuditEvent.count" do
      patch password_change_path, params: { user: { current_password: "wrong", password: "new-password-123", password_confirmation: "new-password-123" } }
    end

    assert_response :unprocessable_entity
  end
end
