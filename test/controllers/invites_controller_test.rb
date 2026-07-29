require "test_helper"

class InvitesControllerTest < ActionDispatch::IntegrationTest
  test "show renders form for a usable invite" do
    get invite_path(invites(:pending_internal).token)
    assert_response :success
  end

  test "show redirects for an unusable invite" do
    get invite_path(invites(:expired).token)
    assert_redirected_to root_path
  end

  test "show redirects for an unknown token" do
    get invite_path("does-not-exist")
    assert_redirected_to root_path
  end

  test "accepting a pending internal invite creates a member user and starts a session" do
    invite = invites(:pending_internal)

    assert_difference("User.count", 1) do
      patch invite_path(invite.token), params: { password: "password123", password_confirmation: "password123" }
    end

    user = User.find_by(email_address: invite.email)
    assert user.present?
    assert cookies[:session_id]
    assert invite.reload.accepted_at.present?

    membership = WorkspaceMembership.find_by(user: user, workspace: workspaces(:primary))
    assert membership.member?
  end

  test "accepting a pending client invite grants the client workspace role" do
    invite = invites(:pending_client)

    patch invite_path(invite.token), params: { password: "password123", password_confirmation: "password123" }

    user = User.find_by(email_address: invite.email)
    membership = WorkspaceMembership.find_by(user: user, workspace: workspaces(:primary))
    assert membership.client?
  end

  test "expired invite is rejected" do
    invite = invites(:expired)

    assert_no_difference("User.count") do
      patch invite_path(invite.token), params: { password: "password123", password_confirmation: "password123" }
    end

    assert_redirected_to root_path
  end

  test "revoked invite is rejected" do
    invite = invites(:revoked)

    assert_no_difference("User.count") do
      patch invite_path(invite.token), params: { password: "password123", password_confirmation: "password123" }
    end

    assert_redirected_to root_path
  end

  test "already accepted invite cannot be used again" do
    invite = invites(:accepted)

    assert_no_difference("User.count") do
      patch invite_path(invite.token), params: { password: "password123", password_confirmation: "password123" }
    end

    assert_redirected_to root_path
  end
end
