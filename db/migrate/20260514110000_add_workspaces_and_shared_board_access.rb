class AddWorkspacesAndSharedBoardAccess < ActiveRecord::Migration[8.1]
  class MigrationUser < ApplicationRecord
    self.table_name = "users"
  end

  class MigrationBoard < ApplicationRecord
    self.table_name = "boards"
  end

  class MigrationWorkspace < ApplicationRecord
    self.table_name = "workspaces"
  end

  class MigrationWorkspaceMembership < ApplicationRecord
    self.table_name = "workspace_memberships"
  end

  def up
    create_table :workspaces do |t|
      t.string :name, null: false
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end

    create_table :workspace_memberships do |t|
      t.references :workspace, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role, null: false, default: 1
      t.timestamps
    end
    add_index :workspace_memberships, [ :workspace_id, :user_id ], unique: true

    add_reference :boards, :workspace, foreign_key: true
    add_index :boards, [ :workspace_id, :position ]

    MigrationUser.reset_column_information
    MigrationBoard.reset_column_information
    MigrationWorkspace.reset_column_information
    MigrationWorkspaceMembership.reset_column_information

    first_user = MigrationUser.order(:id).first

    if first_user
      primary_workspace = MigrationWorkspace.create!(
        name: "Mission Control",
        owner_id: first_user.id,
        created_at: Time.current,
        updated_at: Time.current
      )

      MigrationWorkspaceMembership.create!(
        workspace_id: primary_workspace.id,
        user_id: first_user.id,
        role: 0,
        created_at: Time.current,
        updated_at: Time.current
      )

      personal_workspace_by_user = {}

      MigrationUser.where.not(id: first_user.id).order(:id).find_each do |user|
        workspace = MigrationWorkspace.create!(
          name: "#{user.email_address.split('@').first.titleize} Workspace",
          owner_id: user.id,
          created_at: Time.current,
          updated_at: Time.current
        )

        MigrationWorkspaceMembership.create!(
          workspace_id: workspace.id,
          user_id: user.id,
          role: 0,
          created_at: Time.current,
          updated_at: Time.current
        )

        personal_workspace_by_user[user.id] = workspace.id
      end

      MigrationBoard.find_each do |board|
        workspace_id = board.user_id == first_user.id ? primary_workspace.id : personal_workspace_by_user[board.user_id]
        workspace_id ||= primary_workspace.id
        board.update_columns(workspace_id: workspace_id)
      end

      MigrationUser.where.not(id: first_user.id).find_each do |user|
        MigrationWorkspaceMembership.find_or_create_by!(workspace_id: primary_workspace.id, user_id: user.id) do |membership|
          membership.role = 1
          membership.created_at = Time.current
          membership.updated_at = Time.current
        end
      end
    end

    change_column_null :boards, :workspace_id, false
  end

  def down
    remove_index :boards, [ :workspace_id, :position ]
    remove_reference :boards, :workspace, foreign_key: true
    drop_table :workspace_memberships
    drop_table :workspaces
  end
end
