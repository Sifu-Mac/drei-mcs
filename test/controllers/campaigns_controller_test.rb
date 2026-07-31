require "test_helper"

class CampaignsControllerTest < ActionDispatch::IntegrationTest
  test "internal user creates campaign" do
    sign_in_as users(:admin)

    assert_difference "Campaign.count", 1 do
      post campaigns_path, params: { campaign: { name: "Sommer" } }
    end

    assert_redirected_to boards_path
    assert_equal "Sommer", Campaign.order(:created_at).last.name
  end

  test "internal user renames campaign" do
    sign_in_as users(:admin)

    patch campaign_path(campaigns(:general)), params: { campaign: { name: "Neue Kampagne" } }

    assert_redirected_to boards_path
    assert_equal "Neue Kampagne", campaigns(:general).reload.name
  end

  test "internal user archives and restores campaign" do
    sign_in_as users(:admin)

    patch archive_campaign_path(campaigns(:general))
    assert_redirected_to boards_path
    assert campaigns(:general).reload.archived?

    patch restore_campaign_path(campaigns(:general))
    assert_redirected_to archived_campaigns_path
    assert_not campaigns(:general).reload.archived?
  end

  test "internal user duplicates campaign with cards" do
    sign_in_as users(:admin)

    assert_difference ["Campaign.count", "Board.count", "Task.count"], 1 do
      post duplicate_campaign_path(campaigns(:general))
    end

    assert_redirected_to board_path(Board.order(:created_at).last)
  end

  test "client cannot mutate campaigns" do
    sign_in_as users(:client)

    assert_no_difference "Campaign.count" do
      post campaigns_path, params: { campaign: { name: "Client" } }
    end

    assert_response :not_found
  end

  test "admin permanently deletes an archived campaign after confirming its name" do
    admin = users(:admin)
    campaign = Campaign.unscoped.where(workspace: admin.current_workspace).first
    campaign.archive!
    sign_in_as admin

    assert_difference [ "Campaign.count", "Board.count" ], -1 do
      delete destroy_permanently_campaign_path(campaign), params: { confirmation: campaign.name }
    end

    assert_redirected_to archived_campaigns_path
    assert_equal 1, AuditEvent.where(action: "campaign_deleted_permanently").count
    assert_equal "campaign_deleted_permanently", AuditEvent.order(:created_at).last.action
  end

  test "campaign delete requires admin, archive state, and exact confirmation" do
    campaign = campaigns(:general)
    campaign.archive!
    sign_in_as users(:client)

    assert_no_difference "Campaign.count" do
      delete destroy_permanently_campaign_path(campaign), params: { confirmation: campaign.name }
    end
    assert_response :not_found

    sign_in_as users(:admin)
    assert_no_difference "Campaign.count" do
      delete destroy_permanently_campaign_path(campaign), params: { confirmation: "wrong" }
    end
    assert_redirected_to archived_campaigns_path
  end
end
