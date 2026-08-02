class NullifyDeletedUsersInTaskActivities < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :task_activities, :users
    add_foreign_key :task_activities, :users, on_delete: :nullify
  end

  def down
    remove_foreign_key :task_activities, :users
    add_foreign_key :task_activities, :users
  end
end
