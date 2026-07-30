class CreateCampaigns < ActiveRecord::Migration[8.1]
  def change
    create_table :campaigns do |t|
      t.references :workspace, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.datetime :archived_at
      t.timestamps
    end

    add_index :campaigns, [:workspace_id, :position]
    add_index :campaigns, :archived_at
  end
end
