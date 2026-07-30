class Boards::CommentsController < ApplicationController
  include UploadCleanup

  before_action :set_board
  before_action :set_task

  def create
    @comment = @task.comments.new(comment_params)
    @comment.user = current_user

    if @comment.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to board_task_path(@board, @task), notice: "Kommentar wurde hinzugefügt." }
      end
    else
      purge_new_uploads(@comment, :images)
      respond_to do |format|
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { redirect_to board_task_path(@board, @task), alert: @comment.errors.full_messages.join(", ") }
      end
    end
  end

  private

  def set_board
    @board = current_user.current_workspace_boards.find(params[:board_id])
  end

  def set_task
    @task = @board.tasks.find(params[:task_id])
  end

  def comment_params
    params.require(:task_comment).permit(:body, images: [])
  end
end
