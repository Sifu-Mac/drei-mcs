require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "normalizes, validates and uses a nickname as the display label" do
    user = users(:one)
    user.display_name = "  Sifu   Design  "

    assert user.valid?
    assert_equal "Sifu Design", user.display_name
    assert_equal "Sifu Design", user.display_label
  end

  test "nickname is unique without case sensitivity and falls back to the email alias" do
    users(:one).update!(display_name: "Sifu")
    duplicate = users(:client)
    duplicate.display_name = "sIFu"

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:display_name], "has already been taken"
    duplicate.display_name = nil
    assert_equal "Client", users(:client).display_label
  end

  test "avatar accepts a valid small image" do
    user = users(:admin)
    attach_png(user.avatar)

    assert user.valid?, user.errors.full_messages.join(", ")
  end

  test "avatar rejects spoofed and oversized images" do
    user = users(:admin)
    attach_png(user.avatar, filename: "avatar.jpg", content_type: "image/jpeg")
    assert_not user.valid?
    assert user.errors[:avatar].any? { |message| message.include?("does not match") }

    user.avatar.purge
    attach_png(user.avatar, bytes: png_bytes.ljust(512.kilobytes + 1, "\0"))
    assert_not user.valid?
    assert user.errors[:avatar].any? { |message| message.include?("512 KB or smaller") }
  end

  test "avatar rejects corrupt image data" do
    user = users(:admin)
    user.avatar.attach(io: StringIO.new("broken"), filename: "avatar.png", content_type: "image/png")

    assert_not user.valid?
    assert user.errors[:avatar].any? { |message| message.include?("must be a valid JPEG") }
  end

  test "all workspace roles can see every active board and campaign in their workspace" do
    [users(:admin), users(:one), users(:client)].each do |user|
      assert_includes user.current_workspace_campaigns, campaigns(:general)
      assert_includes user.current_workspace_boards, boards(:one)
    end

    assert_not_includes users(:client).current_workspace_boards, boards(:two)
  end
end
