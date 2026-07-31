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

  test "task view displays the comment author's nickname" do
    task_comments(:one).user.update!(display_name: "Sifu Review")
    sign_in_as users(:client)

    get board_task_path(@board, @task)

    assert_response :success
    assert_includes response.body, "Sifu Review"
  end

  test "task view renders https urls in comments as safe external links" do
    comment = task_comments(:one)
    comment.update!(body: "Details: https://example.test/review?asset=hero&state=ready <script>alert('xss')</script>")

    get board_task_path(@board, @task)

    assert_response :success
    assert_select "#task_comment_#{comment.id} a[href*='example.test/review'][target='_blank'][rel='noopener noreferrer']", count: 1
    assert_includes response.body, 'href="https://example.test/review?asset=hero&amp;state=ready"'
    assert_includes response.body, "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"
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

  test "author edits text without removing existing images" do
    comment = task_comments(:one)
    attach_png(comment.images, filename: "existing.png")
    sign_in_as comment.user

    patch board_task_comment_path(@board, @task, comment), params: { task_comment: { body: "Aktualisierter Kommentar" } }

    assert_redirected_to board_task_path(@board, @task)
    assert_equal "Aktualisierter Kommentar", comment.reload.body
    assert comment.images.attached?
  end

  test "author can delete their own comment" do
    comment = task_comments(:one)
    sign_in_as comment.user

    assert_difference "TaskComment.count", -1 do
      delete board_task_comment_path(@board, @task, comment)
    end

    assert_redirected_to board_task_path(@board, @task)
  end

  test "creates a reply with a quote snapshot" do
    original = task_comments(:one)
    sign_in_as users(:client)

    assert_difference "TaskComment.count", 1 do
      post board_task_comments_path(@board, @task), params: {
        task_comment: { body: "Antwort", quoted_comment_id: original.id }
      }
    end

    reply = TaskComment.order(:created_at).last
    assert_equal original.id, reply.quoted_comment_id
    assert_equal original.body, reply.quoted_comment_body
    assert_equal original.author_label, reply.quoted_comment_author_label
  end

  test "even an admin receives not found when editing another author's comment" do
    comment = task_comments(:one)
    sign_in_as users(:admin)

    patch board_task_comment_path(@board, @task, comment), params: { task_comment: { body: "Nicht erlaubt" } }

    assert_response :not_found
    assert_equal "Test comment one", comment.reload.body
  end

  test "even an admin receives not found when deleting another author's comment" do
    comment = task_comments(:one)
    sign_in_as users(:admin)

    assert_no_difference "TaskComment.count" do
      delete board_task_comment_path(@board, @task, comment)
    end

    assert_response :not_found
  end
end
