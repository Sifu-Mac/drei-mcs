class CampaignsController < ApplicationController
  before_action :require_internal_workspace_member
  before_action :set_campaign, only: [:update, :duplicate, :archive, :restore]

  def create
    workspace = current_user.current_workspace || current_user.owned_workspaces.create!(name: "DREI Asset Review")
    campaign = workspace.campaigns.new(campaign_params)

    if campaign.save
      redirect_to boards_path, notice: "Kampagne wurde erstellt."
    else
      redirect_to boards_path, alert: campaign.errors.full_messages.join(", ")
    end
  end

  def update
    if @campaign.update(campaign_params)
      redirect_back fallback_location: boards_path, notice: "Kampagne wurde umbenannt."
    else
      redirect_back fallback_location: boards_path, alert: @campaign.errors.full_messages.join(", ")
    end
  end

  def duplicate
    copy = @campaign.duplicate_for!(user: current_user)
    board = copy.boards.reorder(:position, :created_at).first
    redirect_to(board ? board_path(board) : boards_path, notice: "Kampagne wurde dupliziert.")
  end

  def archive
    @campaign.archive!
    redirect_to boards_path, notice: "Kampagne wurde archiviert."
  end

  def restore
    @campaign.restore!
    redirect_to archived_campaigns_path, notice: "Kampagne wurde wiederhergestellt."
  end

  def archived
    @campaigns = current_user.current_workspace.campaigns.archived.ordered.includes(:boards)
    @boards = current_user.current_workspace_boards
  end

  private

  def set_campaign
    @campaign = Campaign.unscoped.where(workspace: current_user.current_workspace).find(params[:id])
  end

  def campaign_params
    params.require(:campaign).permit(:name)
  end
end
