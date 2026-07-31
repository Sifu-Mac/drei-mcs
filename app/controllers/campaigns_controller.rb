class CampaignsController < ApplicationController
  before_action :require_internal_workspace_member
  before_action :set_campaign, only: [:update, :duplicate, :archive, :restore, :destroy_permanently]
  require_admin only: :destroy_permanently

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
    AuditEvent.record!(actor: current_user, action: "campaign_archived", target: @campaign, target_label: @campaign.name)
    redirect_to boards_path, notice: "Kampagne wurde archiviert."
  end

  def restore
    @campaign.restore!
    AuditEvent.record!(actor: current_user, action: "campaign_restored", target: @campaign, target_label: @campaign.name)
    redirect_to archived_campaigns_path, notice: "Kampagne wurde wiederhergestellt."
  end

  def destroy_permanently
    unless @campaign.archived?
      return redirect_to(archived_campaigns_path, alert: "Nur archivierte Kampagnen können endgültig gelöscht werden.")
    end

    unless ActiveSupport::SecurityUtils.secure_compare(params[:confirmation].to_s, @campaign.name)
      return redirect_to(archived_campaigns_path, alert: "Der Kampagnenname stimmt nicht überein.")
    end

    name = @campaign.name
    @campaign.destroy_permanently!
    AuditEvent.record!(actor: current_user, action: "campaign_deleted_permanently", target: Campaign, target_label: name)
    redirect_to archived_campaigns_path, notice: "Kampagne wurde endgültig gelöscht."
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
