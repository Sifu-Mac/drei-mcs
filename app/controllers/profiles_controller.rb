class ProfilesController < ApplicationController
  include UploadCleanup
  before_action :require_internal_member_for_avatar_update, only: :update

  def show
    @user = current_user
  end

  def update
    @user = current_user
    previous_avatar_blob_ids = attached_blob_ids(@user, :avatar)
    remove_avatar = params.dig(:user, :remove_avatar) == "1"

    if @user.update(profile_params)
      if remove_avatar
        @user.avatar.purge if @user.avatar.attached?
        @user.update_column(:avatar_url, nil)
      end
      redirect_to settings_path, notice: "Profil wurde gespeichert."
    else
      purge_new_uploads(@user, :avatar, previous_blob_ids: previous_avatar_blob_ids)
      render :show, status: :unprocessable_entity
    end
  end

  def regenerate_api_token
    current_user.api_tokens.destroy_all
    @api_token = current_user.api_tokens.create!
    redirect_to settings_path, notice: "API-Token wurde neu erstellt."
  end

  private

  def require_internal_member_for_avatar_update
    avatar_change = params.dig(:user, :avatar).present? || params.dig(:user, :remove_avatar) == "1"
    require_internal_workspace_member if avatar_change
  end

  def profile_params
    params.expect(user: [ :email_address, :avatar ])
  end
end
