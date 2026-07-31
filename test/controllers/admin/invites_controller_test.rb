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
    assert_equal "Einladung an new-client@example.com wurde zum Versand eingereiht.", flash[:notice]
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

  test "enqueue failure removes the saved invite and shows an error" do
    sign_in_as(@admin)
    delivery = Object.new
    delivery.define_singleton_method(:deliver_later) do
      raise ActiveJob::EnqueueError, "test enqueue failure"
    end

    assert_no_difference("Invite.count") do
      with_invite_delivery(delivery) do
        post admin_invites_path, params: { invite: { email: "queue-failure@example.com", role: "client" } }
      end
    end

    assert_response :unprocessable_entity
    assert_select ".text-red-400", text: /Einladung konnte nicht zum Versand eingereiht werden/
    assert_not Invite.exists?(email: "queue-failure@example.com")
  end

  test "unsuccessful enqueue result removes the saved invite" do
    sign_in_as(@admin)
    delivery = Object.new
    delivery.define_singleton_method(:deliver_later) { false }

    assert_no_difference("Invite.count") do
      with_invite_delivery(delivery) do
        post admin_invites_path, params: { invite: { email: "queue-rejected@example.com", role: "internal" } }
      end
    end

    assert_response :unprocessable_entity
    assert_not Invite.exists?(email: "queue-rejected@example.com")
  end

  test "revoking an invite sets revoked_at" do
    sign_in_as(@admin)
    invite = invites(:pending_internal)

    delete admin_invite_path(invite)

    assert_redirected_to admin_invites_path
    assert invite.reload.revoked_at.present?
  end

  private

  def with_invite_delivery(delivery)
    original_method = InviteMailer.method(:invitation)
    InviteMailer.define_singleton_method(:invitation) { |_invite| delivery }
    yield
  ensure
    InviteMailer.define_singleton_method(:invitation, original_method)
  end
end
