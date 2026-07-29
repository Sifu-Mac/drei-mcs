require "test_helper"

class InviteTest < ActiveSupport::TestCase
  test "generates token on create" do
    invite = Invite.create!(email: "new-invite@example.com", invited_by: users(:admin))

    assert invite.token.present?
    assert_equal 64, invite.token.length # 32 bytes hex = 64 chars
  end

  test "token must be unique" do
    existing = invites(:pending_internal)
    duplicate = Invite.new(email: "other@example.com", invited_by: users(:admin), token: existing.token)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:token], "has already been taken"
  end

  test "defaults expires_at to about 7 days from now" do
    invite = Invite.create!(email: "new-invite@example.com", invited_by: users(:admin))

    assert_in_delta 7.days.from_now.to_i, invite.expires_at.to_i, 5
  end

  test "normalizes email" do
    invite = Invite.new(email: " SOMEONE@EXAMPLE.COM ")
    assert_equal("someone@example.com", invite.email)
  end

  test "pending invite is usable" do
    assert invites(:pending_internal).usable?
    assert_equal "pending", invites(:pending_internal).status
  end

  test "expired invite is not usable" do
    assert_not invites(:expired).usable?
    assert_equal "expired", invites(:expired).status
  end

  test "revoked invite is not usable" do
    assert_not invites(:revoked).usable?
    assert_equal "revoked", invites(:revoked).status
  end

  test "accepted invite is not usable" do
    assert_not invites(:accepted).usable?
    assert_equal "accepted", invites(:accepted).status
  end

  test "belongs to invited_by" do
    assert_equal users(:admin), invites(:pending_internal).invited_by
  end
end
