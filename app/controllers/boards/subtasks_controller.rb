class Boards::SubtasksController < ApplicationController
  before_action :set_board
  before_action :set_task
  before_action :set_subtask, only: [ :update, :destroy ]

  def create
    @subtask = @task.subtasks.new(subtask_params)
    if @subtask.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: subtask_stream_updates
        end
        format.html { redirect_to board_task_path(@board, @task) }
      end
    else
      head :unprocessable_entity
    end
  end

  def update
    @subtask.update(subtask_params)
    respond_to do |format|
      format.turbo_stream do
          render turbo_stream: subtask_stream_updates
      end
      format.html { redirect_to board_task_path(@board, @task) }
    end
  end

  def destroy
    @subtask.destroy
    respond_to do |format|
      format.turbo_stream do
          render turbo_stream: subtask_stream_updates
      end
      format.html { redirect_to board_task_path(@board, @task) }
    end
  end

  private

  def set_board
    @board = current_user.current_workspace_boards.find(params[:board_id])
  end

  def set_task
    @task = @board.tasks.find(params[:task_id])
  end

  def set_subtask
    @subtask = @task.subtasks.find(params[:id])
  end

  def subtask_params
    params.require(:subtask).permit(:title, :done)
  end

  def subtask_stream_updates
    refreshed_task = @task.reload
    [
      turbo_stream.replace("task_#{refreshed_task.id}_subtasks", partial: "boards/tasks/subtasks", locals: { task: refreshed_task, board: @board }),
      turbo_stream.replace("task_#{refreshed_task.id}", partial: "boards/task_card", locals: { task: refreshed_task })
    ]
  end
end
