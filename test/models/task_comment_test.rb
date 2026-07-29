require "test_helper"
require "stringio"

class TaskCommentTest < ActiveSupport::TestCase
  setup do
    @comment = task_comments(:one)
  end

  test "comment with text only is valid" do
    assert @comment.valid?
    assert_not @comment.images.attached?
  end

  test "comment accepts one image" do
    attach_file(@comment.images, filename: "comment.png", content_type: "image/png")

    assert @comment.valid?, @comment.errors.full_messages.join(", ")
    assert_equal 1, @comment.images.size
  end

  test "comment accepts multiple images" do
    attach_file(@comment.images, filename: "comment-1.jpg", content_type: "image/jpeg")
    attach_file(@comment.images, filename: "comment-2.webp", content_type: "image/webp")
    attach_file(@comment.images, filename: "comment-3.gif", content_type: "image/gif")

    assert @comment.valid?, @comment.errors.full_messages.join(", ")
    assert_equal 3, @comment.images.size
  end

  test "comment rejects invalid image type" do
    attach_file(@comment.images, filename: "payload.svg", content_type: "image/svg+xml")

    assert_not @comment.valid?
    assert @comment.errors[:images].any? { |message| message.include?("must be a JPEG, PNG, WebP, or GIF image") }
  end

  test "comment rejects image over five megabytes" do
    attach_file(@comment.images, filename: "large.png", content_type: "image/png", size: 5.megabytes + 1)

    assert_not @comment.valid?
    assert @comment.errors[:images].any? { |message| message.include?("must be 5 MB or smaller") }
  end

  private

  def attach_file(attachments, filename:, content_type:, size: 128)
    attachments.attach(
      io: StringIO.new("a" * size),
      filename: filename,
      content_type: content_type
    )
  end
end
