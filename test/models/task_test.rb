require "test_helper"
require "stringio"

class TaskTest < ActiveSupport::TestCase
  setup do
    @task = tasks(:one)
  end

  test "task without cover image is valid" do
    assert @task.valid?
    assert_not @task.cover_image.attached?
  end

  test "task accepts valid cover image types" do
    {
      "cover.jpg" => "image/jpeg",
      "cover.png" => "image/png",
      "cover.webp" => "image/webp",
      "cover.gif" => "image/gif"
    }.each do |filename, content_type|
      task = tasks(:one)
      task.cover_image.purge if task.cover_image.attached?
      attach_file(task.cover_image, filename: filename, content_type: content_type)

      assert task.valid?, "#{content_type} should be valid: #{task.errors.full_messages.join(', ')}"
    end
  end

  test "task rejects invalid cover image type" do
    attach_file(@task.cover_image, filename: "script.svg", content_type: "image/svg+xml")

    assert_not @task.valid?
    assert_includes @task.errors[:cover_image], "must be a JPEG, PNG, WebP, or GIF image"
  end

  test "task rejects cover image over five megabytes" do
    attach_file(@task.cover_image, filename: "large.png", content_type: "image/png", size: 5.megabytes + 1)

    assert_not @task.valid?
    assert_includes @task.errors[:cover_image], "must be 5 MB or smaller"
  end

  private

  def attach_file(attachment, filename:, content_type:, size: 128)
    attachment.attach(
      io: StringIO.new("a" * size),
      filename: filename,
      content_type: content_type
    )
  end
end
