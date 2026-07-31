class SimplifyRolesAndCreateAuditEvents < ActiveRecord::Migration[8.1]
  def up
    WorkspaceMembership.where.not(role: WorkspaceMembership.roles.fetch("client")).update_all(role: WorkspaceMembership.roles.fetch("client"))
    Invite.where.not(role: Invite.roles.fetch("client")).update_all(role: Invite.roles.fetch("client"))
    change_column_default :workspace_memberships, :role, from: 1, to: 2
    change_column_default :invites, :role, from: 0, to: 1

    create_table :audit_events do |t|
      t.references :actor, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :action, null: false
      t.string :target_type, null: false
      t.bigint :target_id
      t.string :target_label, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :audit_events, :created_at
    add_index :audit_events, [ :target_type, :target_id ]
  end

  def down
    drop_table :audit_events
    change_column_default :invites, :role, from: 1, to: 0
    change_column_default :workspace_memberships, :role, from: 2, to: 1
  end
end
