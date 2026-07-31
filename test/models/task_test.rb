require "test_helper"
class TaskTest < ActiveSupport::TestCase
  setup do
    @task = tasks(:one)
  end

  test "task without cover image is valid" do
    assert @task.valid?
    assert_not @task.cover_image.attached?
  end

  test "task accepts a valid cover image" do
    attach_png(@task.cover_image)

    assert @task.valid?, @task.errors.full_messages.join(", ")
  end

  test "task rejects invalid cover image type" do
    @task.cover_image.attach(io: StringIO.new("<svg><script /></svg>"), filename: "script.svg", content_type: "image/svg+xml")

    assert_not @task.valid?
    assert @task.errors[:cover_image].any? { |message| message.include?("must be a valid JPEG") }
  end

  test "task rejects cover image over five megabytes" do
    attach_png(@task.cover_image, filename: "large.png", bytes: png_bytes.ljust(5.megabytes + 1, "\0"))

    assert_not @task.valid?
    assert @task.errors[:cover_image].any? { |message| message.include?("5 MB or smaller") }
  end

  test "task rejects empty and MIME-spoofed cover images" do
    @task.cover_image.attach(io: StringIO.new(""), filename: "empty.png", content_type: "image/png")
    assert_not @task.valid?
    assert @task.errors[:cover_image].any? { |message| message.include?("must not be empty") }

    @task.cover_image.purge
    attach_png(@task.cover_image, filename: "payload.jpg", content_type: "image/jpeg")
    assert_not @task.valid?
    assert @task.errors[:cover_image].any? { |message| message.include?("does not match") }
  end

  test "task rejects corrupt data declared as an image" do
    @task.cover_image.attach(io: StringIO.new("not an image"), filename: "fake.png", content_type: "image/png")

    assert_not @task.valid?
    assert @task.errors[:cover_image].any? { |message| message.include?("must be a valid JPEG") }
  end

  test "completion and blocked state follow board column kind" do
    task = tasks(:one)

    task.update!(board_column: board_columns(:one_done))
    assert task.completed?
    assert task.completed_at.present?
    assert_equal "done", task.status

    task.update!(board_column: board_columns(:one_blocked))
    assert task.blocked?
    assert_not task.completed?
    assert_nil task.completed_at
    assert_equal "blocked", task.status
  end

  test "color accepts allowed values" do
    Task::COLOR_VALUES.each do |color|
      @task.color = color
      assert @task.valid?, "#{color} should be valid"
    end
  end

  test "color rejects invalid values" do
    @task.color = "magenta"

    assert_not @task.valid?
  end
end
