require "test_helper"

class Admin::InvitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @member = users(:one)
  end

  test "admin can create an invite" do
    sign_in_as(@admin)

    assert_difference("Invite.count", 1) do
      post admin_invites_path, params: { invite: { email: "new-client@example.com", role: "client" } }
    end

    assert_redirected_to admin_invites_path
    assert_predicate Invite.find_by!(email: "new-client@example.com"), :client?
  end

  test "non-admin cannot access invites admin area" do
    sign_in_as(@member)

    assert_no_difference("Invite.count") do
      post admin_invites_path, params: { invite: { email: "new-hire@example.com", role: "internal" } }
    end

    assert_response :not_found
  end

  test "cannot invite an email that already has an account" do
    sign_in_as(@admin)

    assert_no_difference("Invite.count") do
      post admin_invites_path, params: { invite: { email: @member.email_address, role: "internal" } }
    end

    assert_response :unprocessable_entity
  end

  test "cannot invite an email with an existing pending invite" do
    sign_in_as(@admin)
    pending_email = invites(:pending_internal).email

    assert_no_difference("Invite.count") do
      post admin_invites_path, params: { invite: { email: pending_email, role: "internal" } }
    end

    assert_response :unprocessable_entity
  end

  test "revoking an invite sets revoked_at" do
    sign_in_as(@admin)
    invite = invites(:pending_internal)

    delete admin_invite_path(invite)

    assert_redirected_to admin_invites_path
    assert invite.reload.revoked_at.present?
  end
end
