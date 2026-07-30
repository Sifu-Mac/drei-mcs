class AddCampaignAndArchivedAtToBoards < ActiveRecord::Migration[8.1]
  class MigrationWorkspace < ActiveRecord::Base
    self.table_name = "workspaces"
  end

  class MigrationCampaign < ActiveRecord::Base
    self.table_name = "campaigns"
  end

  class MigrationBoard < ActiveRecord::Base
    self.table_name = "boards"
  end

  def up
    add_reference :boards, :campaign, foreign_key: true
    add_column :boards, :archived_at, :datetime
    add_index :boards, :archived_at

    MigrationWorkspace.reset_column_information
    MigrationCampaign.reset_column_information
    MigrationBoard.reset_column_information

    MigrationWorkspace.find_each do |workspace|
      campaign = MigrationCampaign.create!(workspace_id: workspace.id, name: "Allgemein", position: 1)
      MigrationBoard.where(workspace_id: workspace.id, campaign_id: nil).update_all(campaign_id: campaign.id)
    end

    change_column_null :boards, :campaign_id, false
  end

  def down
    remove_reference :boards, :campaign, foreign_key: true
    remove_column :boards, :archived_at
  end
end
