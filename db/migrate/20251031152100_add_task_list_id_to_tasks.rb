class AddTaskListIdToTasks < ActiveRecord::Migration[8.1]
  class MigrationProject < ActiveRecord::Base
    self.table_name = "projects"
  end

  class MigrationTaskList < ActiveRecord::Base
    self.table_name = "task_lists"
  end

  class MigrationTask < ActiveRecord::Base
    self.table_name = "tasks"
  end

  def up
    # Add the column as nullable first
    add_reference :tasks, :task_list, null: true, foreign_key: true

    # Create default task lists for existing projects and associate tasks
    MigrationProject.find_each do |project|
      task_list = MigrationTaskList.create!(
        title: "Tasks",
        project_id: project.id,
        user_id: project.user_id,
        position: 1,
        created_at: Time.current,
        updated_at: Time.current
      )
      MigrationTask.where(project_id: project.id).update_all(task_list_id: task_list.id)
    end

    # Now make it non-nullable
    change_column_null :tasks, :task_list_id, false
  end

  def down
    remove_reference :tasks, :task_list, foreign_key: true
  end
end
