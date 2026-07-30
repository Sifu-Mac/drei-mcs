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
    column = if params[:board_column_id].present?
      @board.board_columns.find(params[:board_column_id])
    elsif params[:status].present?
      @board.column_for_legacy_status(params[:status])
    end

    if params[:task_ids].present?
      params[:task_ids].each_with_index do |task_id, index|
        task = @board.tasks.find(task_id)
        updates = { position: index + 1 }
        updates[:board_column_id] = column.id if column
        task.update!(updates)
      end
    end

    if params[:task_id].present? && column
      @task = @board.tasks.find(params[:task_id])
      @task.activity_source = "web"
      @task.update!(board_column: column)
    end

    head :ok
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
