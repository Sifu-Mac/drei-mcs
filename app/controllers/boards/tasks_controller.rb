class Boards::TasksController < ApplicationController
  include UploadCleanup

  before_action :set_board
  before_action :set_task, only: [:show, :edit, :update, :destroy, :assign, :unassign, :duplicate, :archive, :restore]
  before_action :require_internal_workspace_member, except: [:show, :archived, :create, :duplicate]
  before_action :require_task_creation_or_duplication_permission, only: [:create, :duplicate]

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
    previous_cover_blob_ids = attached_blob_ids(@task, :cover_image)
    @task.activity_source = "web"
    if @task.update(task_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to(request.referer.presence || board_task_path(@board, @task), notice: "Karte wurde aktualisiert.") }
      end
    else
      purge_new_uploads(@task, :cover_image, previous_blob_ids: previous_cover_blob_ids)
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
    require_internal_workspace_member
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
    raise ActionController::RoutingError, "Not Found" if action_name == "duplicate" && client_workspace_member? && @task.archived_at.present?
  end

  def task_params
    permitted = if client_workspace_member?
      params.require(:task).permit(:name, :title, :board_column_id)
    else
      params.require(:task).permit(:name, :title, :description, :priority, :status, :owner, :blocked, :due_date, :completed, :agent_hint, :cover_image, :board_column_id, :color, tags: [])
    end
    permitted[:name] = permitted.delete(:title) if permitted[:title].present? && permitted[:name].blank?
    permitted[:board_column_id] = @board.board_columns.find(permitted[:board_column_id]).id if permitted[:board_column_id].present?
    permitted
  end

  def require_task_creation_or_duplication_permission
    raise ActionController::RoutingError, "Not Found" unless internal_workspace_member? || client_workspace_member?
  end
end
