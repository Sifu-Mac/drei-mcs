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

  test "stores a durable quote snapshot when the original comment is deleted" do
    original = task_comments(:one)
    original.user.update!(display_name: "Alex")
    reply = TaskComment.create!(task: original.task, user: users(:admin), body: "Meine Antwort", quoted_comment: original)

    assert_equal original.body, reply.quoted_comment_body
    assert_equal original.author_label, reply.quoted_comment_author_label

    original.destroy!
    reply.reload

    assert_nil reply.quoted_comment_id
    assert_equal "Test comment one", reply.quoted_body
    assert_equal "Alex", reply.quoted_author_label
  end

  test "rejects quotes from another task" do
    @comment.quoted_comment = task_comments(:two)

    assert_not @comment.valid?
    assert_includes @comment.errors[:quoted_comment], "must belong to the same task"
  end
end
