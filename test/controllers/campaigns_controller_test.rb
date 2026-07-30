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
end
