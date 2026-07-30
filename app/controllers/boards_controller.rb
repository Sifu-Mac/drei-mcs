class BoardsController < ApplicationController
  before_action :set_board, only: [:show, :update, :destroy, :duplicate, :archive, :restore, :update_task_status]
  before_action :require_internal_workspace_member, only: [:create, :update, :destroy, :duplicate, :archive, :restore, :update_task_status]

  def index
    workspace = current_user.current_workspace || current_user.owned_workspaces.create!(name: "DREI Asset Review")
    @board = current_user.current_workspace_boards.reorder(:position, :created_at).first

    if @board
      redirect_to board_path(@board)
    elsif internal_workspace_member?
      campaign = workspace.campaigns.active.find_or_create_by!(name: "Allgemein")
      @board = workspace.boards.create!(user: current_user, campaign: campaign, name: "DREI Asset Review", icon: "📋", color: "gray", column_template: "standard_review")
      redirect_to board_path(@board)
    else
      redirect_to home_path, alert: "Es ist noch kein Board verfügbar."
    end
  end

  def show
    @board_page = true
    @active_campaign = @board.campaign
    session[:last_board_id] = @board.id
    @tasks = @board.tasks.includes(:user, :board_column)

    if params[:tag].present?
      @tasks = @tasks.where("? = ANY(tags)", params[:tag])
      @current_tag = params[:tag]
    end

    @board_columns = @board.board_columns.ordered
    @columns = @board_columns.index_with { |column| @tasks.where(board_column_id: column.id).reorder(:position, :created_at) }
    @all_tags = @board.tasks.where.not(tags: []).pluck(:tags).flatten.uniq.sort
    @campaigns = current_user.current_workspace_campaigns.includes(:boards)
    @boards = current_user.current_workspace_boards
    @api_token = current_user.api_token
  end

  def create
    workspace = current_user.current_workspace || current_user.owned_workspaces.create!(name: "DREI Asset Review")
    campaign = workspace.campaigns.active.find(params[:board][:campaign_id])
    @board = workspace.boards.new(board_params.merge(user: current_user, campaign: campaign))
    @board.column_template = params[:board][:column_template]

    if @board.save
      redirect_to board_path(@board), notice: "Board wurde erstellt."
    else
      redirect_to boards_path, alert: @board.errors.full_messages.join(", ")
    end
  end

  def update
    if @board.update(board_params)
      redirect_back fallback_location: board_path(@board), notice: "Board wurde umbenannt."
    else
      redirect_to board_path(@board), alert: @board.errors.full_messages.join(", ")
    end
  end

  def destroy
    archive
  end

  def duplicate
    copy = @board.duplicate_to!(campaign: @board.campaign, user: current_user)
    redirect_to board_path(copy), notice: "Board wurde dupliziert."
  end

  def archive
    if @board.campaign.boards.count <= 1 && @board.workspace.campaigns.active.joins(:boards).where(boards: { archived_at: nil }).distinct.count <= 1
      redirect_to board_path(@board), alert: "Das einzige aktive Board kann nicht archiviert werden."
      return
    end

    @board.archive!
    redirect_to boards_path, notice: "Board wurde archiviert."
  end

  def restore
    @board.restore!
    @board.campaign.restore! if @board.campaign.archived?
    redirect_to board_path(@board), notice: "Board wurde wiederhergestellt."
  end

  def update_task_status
    target_column = @board.board_columns.find(params[:board_column_id])
    source_column = @board.board_columns.find(params[:source_column_id] || target_column.id)
    ordered_ids = Array(params[:task_ids]).map(&:to_s)
    moved_task = @board.tasks.find(params[:task_id])

    Task.transaction do
      involved_tasks = @board.tasks.where(board_column_id: [source_column.id, target_column.id]).lock.to_a
      current_source_id = involved_tasks.find { |task| task.id == moved_task.id }&.board_column_id
      raise ActiveRecord::StaleObjectError.new(moved_task, "move") unless current_source_id == source_column.id

      expected_ids = involved_tasks
        .select { |task| task.board_column_id == target_column.id || task.id == moved_task.id }
        .map { |task| task.id.to_s }

      unless ordered_ids.uniq.length == ordered_ids.length && ordered_ids.sort == expected_ids.sort
        raise ActionController::BadRequest, "Ungültige oder veraltete Kartenreihenfolge."
      end

      ordered_ids.each_with_index do |task_id, index|
        task = involved_tasks.find { |candidate| candidate.id.to_s == task_id }
        task.activity_source = "web"
        task.update!(board_column: target_column, position: index + 1)
      end

      if source_column != target_column
        involved_tasks
          .select { |task| task.board_column_id == source_column.id && task.id != moved_task.id }
          .sort_by(&:position)
          .each_with_index { |task, index| task.update!(position: index + 1) }
      end
    end

    head :ok
  rescue ActiveRecord::RecordInvalid => error
    render json: { error: error.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  rescue ActiveRecord::StaleObjectError
    render json: { error: "Das Board wurde zwischenzeitlich geändert. Bitte erneut versuchen." }, status: :conflict
  rescue ActionController::BadRequest => error
    render json: { error: error.message }, status: :unprocessable_entity
  end

  private

  def set_board
    @board = Board.unscoped.joins(:campaign)
      .where(workspace_id: current_user.current_workspace&.id)
      .where(campaigns: { workspace_id: current_user.current_workspace&.id })
      .find(params[:id])
  end

  def board_params
    params.require(:board).permit(:name, :icon, :color)
  end
end
