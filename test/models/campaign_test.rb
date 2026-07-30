require "test_helper"

class CampaignTest < ActiveSupport::TestCase
  test "name is required" do
    campaign = Campaign.new(workspace: workspaces(:primary))

    assert_not campaign.valid?
    assert_includes campaign.errors[:name], "can't be blank"
  end

  test "archive and restore toggle archived state" do
    campaign = campaigns(:general)

    campaign.archive!
    assert campaign.archived?
    assert_not_includes Campaign.active, campaign

    campaign.restore!
    assert_not campaign.archived?
    assert_includes Campaign.active, campaign
  end

  test "duplicate copies boards and cards without comments or uploads" do
    source = campaigns(:general)
    source_board_ids = source.boards.pluck(:id)

    copy = source.duplicate_for!(user: users(:admin))

    assert_equal "#{source.name} Kopie", copy.name
    assert_equal source.boards.count, copy.boards.count
    copied_board = copy.boards.first
    assert_not_includes source_board_ids, copied_board.id
    assert_equal source.boards.first.board_columns.count, copied_board.board_columns.count
    assert_equal source.boards.first.tasks.count, copied_board.tasks.count
    assert_equal copied_board.id, copied_board.tasks.first.board_id
    assert_empty copied_board.tasks.first.comments
    assert_not copied_board.tasks.first.cover_image.attached?
    assert_empty copied_board.tasks.first.activities
  end
end
