class AddOwnerAndMcsStatusesToTasks < ActiveRecord::Migration[8.1]
  def up
    add_column :tasks, :owner, :integer, default: 0, null: false
    add_index :tasks, :owner

    execute <<~SQL
      UPDATE tasks
      SET status = CASE status
        WHEN 4 THEN 6
        WHEN 3 THEN 5
        WHEN 2 THEN 3
        WHEN 1 THEN 2
        ELSE 0
      END
    SQL

    execute <<~SQL
      UPDATE tasks
      SET status = 4
      WHERE blocked = TRUE AND status != 6
    SQL

    execute <<~SQL
      UPDATE tasks
      SET owner = CASE
        WHEN assigned_to_agent = TRUE THEN 1
        ELSE 0
      END
    SQL
  end

  def down
    remove_index :tasks, :owner
    remove_column :tasks, :owner

    execute <<~SQL
      UPDATE tasks
      SET blocked = CASE WHEN status = 4 THEN TRUE ELSE blocked END,
          status = CASE status
            WHEN 6 THEN 4
            WHEN 5 THEN 3
            WHEN 4 THEN 2
            WHEN 3 THEN 2
            WHEN 2 THEN 1
            WHEN 1 THEN 1
            ELSE 0
          END
    SQL
  end
end
