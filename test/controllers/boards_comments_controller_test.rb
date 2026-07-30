require "test_helper"

class BoardsCommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin)
    @board = boards(:one)
    @task = tasks(:one)
    sign_in_as @user
  end

  test "creates a comment with a valid image" do
    assert_difference "TaskComment.count", 1 do
      post board_task_comments_path(@board, @task),
        params: { task_comment: { body: "Screenshot", images: [ uploaded_png ] } }
    end

    assert_redirected_to board_task_path(@board, @task)
    assert TaskComment.order(:created_at).last.images.attached?
  end

  test "rejects corrupt image without retaining attachment or blob" do
    assert_no_difference [ "TaskComment.count", "ActiveStorage::Attachment.count", "ActiveStorage::Blob.count" ] do
      post board_task_comments_path(@board, @task),
        params: {
          task_comment: {
            body: "Spoof",
            images: [ uploaded_png(filename: "fake.png", bytes: "not an image") ]
          }
        }
    end

    assert_redirected_to board_task_path(@board, @task)
    assert_includes flash[:alert], "must be a valid JPEG"
  end

  test "rejects more than five images and purges all uploaded blobs" do
    uploads = 6.times.map { |index| uploaded_png(filename: "image-#{index}.png") }

    assert_no_difference [ "TaskComment.count", "ActiveStorage::Attachment.count", "ActiveStorage::Blob.count" ] do
      post board_task_comments_path(@board, @task),
        params: { task_comment: { body: "Zu viele", images: uploads } }
    end

    assert_redirected_to board_task_path(@board, @task)
    assert_includes flash[:alert], "no more than 5 images"
  end
end
