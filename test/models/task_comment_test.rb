require "test_helper"
class TaskCommentTest < ActiveSupport::TestCase
  setup do
    @comment = task_comments(:one)
  end

  test "comment with text only is valid" do
    assert @comment.valid?
    assert_not @comment.images.attached?
  end

  test "comment accepts one image" do
    attach_png(@comment.images, filename: "comment.png")

    assert @comment.valid?, @comment.errors.full_messages.join(", ")
    assert_equal 1, @comment.images.size
  end

  test "comment accepts multiple images within the limit" do
    3.times { |index| attach_png(@comment.images, filename: "comment-#{index}.png") }

    assert @comment.valid?, @comment.errors.full_messages.join(", ")
    assert_equal 3, @comment.images.size
  end

  test "comment rejects invalid image type" do
    @comment.images.attach(io: StringIO.new("<svg />"), filename: "payload.svg", content_type: "image/svg+xml")

    assert_not @comment.valid?
    assert @comment.errors[:images].any? { |message| message.include?("must be a valid JPEG") }
  end

  test "comment rejects image over five megabytes" do
    attach_png(@comment.images, filename: "large.png", bytes: png_bytes.ljust(5.megabytes + 1, "\0"))

    assert_not @comment.valid?
    assert @comment.errors[:images].any? { |message| message.include?("must be 5 MB or smaller") }
  end

  test "comment rejects more than five images" do
    6.times { |index| attach_png(@comment.images, filename: "comment-#{index}.png") }

    assert_not @comment.valid?
    assert_includes @comment.errors[:images], "must contain no more than 5 images"
  end

  test "comment rejects MIME-spoofed images" do
    attach_png(@comment.images, filename: "fake.jpg", content_type: "image/jpeg")

    assert_not @comment.valid?
    assert @comment.errors[:images].any? { |message| message.include?("does not match") }
  end
end
