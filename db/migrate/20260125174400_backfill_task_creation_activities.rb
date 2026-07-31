class BackfillTaskCreationActivities < ActiveRecord::Migration[8.1]
  class MigrationTask < ActiveRecord::Base
    self.table_name = "tasks"
  end

  class MigrationTaskActivity < ActiveRecord::Base
    self.table_name = "task_activities"
  end

  def up
    MigrationTask.find_each do |task|
      MigrationTaskActivity.create!(
        task_id: task.id,
        user_id: task.user_id,
        action: "created",
        source: "web",
        created_at: task.created_at,
        updated_at: task.created_at
      )
    end
  end

  def down
    MigrationTaskActivity.where(action: "created").delete_all
  end
end
