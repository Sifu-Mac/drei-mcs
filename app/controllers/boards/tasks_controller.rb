class Boards::TasksController < ApplicationController
  include UploadCleanup

  before_action :set_board
  before_action :set_task, only: [:show, :edit, :update, :destroy, :assign, :unassign, :duplicate, :transfer, :copy_to_board, :move_to_board, :archive, :restore]
  before_action :require_internal_workspace_member, only: [:assign, :unassign]

  def show
    @api_token = current_user.api_token
    @boards = current_user.current_workspace_boards
    render layout: false if turbo_frame_request?
  end

  def new
    @task = @board.tasks.new(user: current_user, board_column_id: params[:board_column_id] || @board.board_columns.ordered.first&.id)
    render layout: false
  end

  def create
    @task = @board.tasks.new(task_params)
    @task.user = current_user
    @task.activity_source = "web"

    if @task.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to board_path(@board), notice: "Karte wurde erstellt." }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :new, status: :unprocessable_entity, layout: false }
        format.html { render :new, status: :unprocessable_entity, layout: false }
      end
    end
  end

  def edit
    render layout: false
  end

  def update
    @task.activity_source = "web"
    if @task.update(task_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to(request.referer.presence || board_task_path(@board, @task), notice: "Karte wurde aktualisiert.") }
      end
    else
      render :show, status: :unprocessable_entity, layout: false
    end
  end

  def duplicate
    @copy = @task.duplicate_for!(user: current_user)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to board_path(@board), notice: "Karte wurde dupliziert." }
    end
  end

  def transfer
    @transfer_mode = params[:mode].to_s
    raise ActionController::RoutingError, "Not Found" unless %w[copy move].include?(@transfer_mode)

    @transfer_boards = current_user.current_workspace_boards.where.not(id: @board.id).includes(:board_columns).ordered
  end

  def copy_to_board
    destination_board, destination_column = transfer_destination
    copy = @task.copy_to_board!(board: destination_board, board_column: destination_column, user: current_user)
    redirect_to board_path(destination_board), notice: "Karte wurde vollständig in #{destination_board.name} kopiert."
  rescue ArgumentError, ActionController::ParameterMissing => error
    redirect_to transfer_board_task_path(@board, @task, mode: "copy"), alert: error.message
  end

  def move_to_board
    destination_board, destination_column = transfer_destination
    @task.move_to_board!(board: destination_board, board_column: destination_column, user: current_user)
    redirect_to board_path(destination_board), notice: "Karte wurde nach #{destination_board.name} verschoben."
  rescue ArgumentError, ActionController::ParameterMissing => error
    redirect_to transfer_board_task_path(@board, @task, mode: "move"), alert: error.message
  end

  def archive
    @task.activity_source = "web"
    @task.archive!
    respond_to do |format|
      format.turbo_stream { render :destroy }
      format.html { redirect_to board_path(@board), notice: "Karte wurde archiviert." }
    end
  end

  def restore
    @task.restore!
    redirect_to archived_board_tasks_path(@board), notice: "Karte wurde wiederhergestellt."
  end

  def archived
    @tasks = @board.tasks.unscoped.where(board_id: @board.id).where.not(archived_at: nil).includes(:board_column).order(archived_at: :desc)
  end

  def destroy
    @board_column = @task.board_column
    @task.activity_source = "web"
    @task.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to board_path(@board), notice: "Karte wurde gelöscht." }
    end
  end

  def assign
    @task.activity_source = "web"
    @task.assign_to_agent!
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("task_#{@task.id}", partial: "boards/task_card", locals: { task: @task }),
          turbo_stream.replace("task_#{@task.id}_agent_assignment", partial: "boards/tasks/agent_assignment", locals: { task: @task, board: @board })
        ]
      end
      format.html { redirect_to board_path(@board), notice: "Karte wurde dem Agent zugewiesen." }
    end
  end

  def unassign
    @task.activity_source = "web"
    @task.unassign_from_agent!
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("task_#{@task.id}", partial: "boards/task_card", locals: { task: @task }),
          turbo_stream.replace("task_#{@task.id}_agent_assignment", partial: "boards/tasks/agent_assignment", locals: { task: @task, board: @board })
        ]
      end
      format.html { redirect_to board_path(@board), notice: "Zuweisung wurde entfernt." }
    end
  end

  private

  def set_board
    @board = current_user.current_workspace_boards.find(params[:board_id])
  end

  def set_task
    @task = @board.tasks.unscoped.where(board_id: @board.id).includes(:activities, comments: :user).find(params[:id])
    raise ActionController::RoutingError, "Not Found" if %w[duplicate transfer copy_to_board move_to_board].include?(action_name) && @task.archived_at.present?
  end

  def transfer_destination
    board_id, column_id = params.require(:transfer).fetch(:destination).to_s.split(":", 2)
    raise ArgumentError, "Bitte Zielboard und Zielspalte auswählen" if board_id.blank? || column_id.blank?
    destination_board = current_user.current_workspace_boards.find(board_id)
    [ destination_board, destination_board.board_columns.find(column_id) ]
  end

  def task_params
    permitted = params.require(:task).permit(:name, :title, :description, :board_column_id, :color, tags: [])
    permitted[:name] = permitted.delete(:title) if permitted[:title].present? && permitted[:name].blank?
    permitted[:board_column_id] = @board.board_columns.find(permitted[:board_column_id]).id if permitted[:board_column_id].present?
    permitted
  end
end
