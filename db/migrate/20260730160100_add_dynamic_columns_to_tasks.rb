class AddDynamicColumnsToTasks < ActiveRecord::Migration[8.1]
  class MigrationBoard < ActiveRecord::Base
    self.table_name = "boards"
  end

  class MigrationBoardColumn < ActiveRecord::Base
    self.table_name = "board_columns"
  end

  class MigrationTask < ActiveRecord::Base
    self.table_name = "tasks"
  end

  KIND_VALUES = { backlog: 0, active: 1, review: 2, blocked: 3, done: 4 }.freeze
  STATUS_TO_COLUMN = {
    0 => ["Eingang", :backlog],
    1 => ["Eingang", :backlog],
    2 => ["In Bearbeitung", :active],
    3 => ["In Bearbeitung", :active],
    4 => ["Änderungen angefordert", :blocked],
    5 => ["Kunden-Review", :review],
    6 => ["Freigegeben", :done]
  }.freeze
  TEMPLATE = [
    ["Eingang", :backlog],
    ["In Bearbeitung", :active],
    ["Kunden-Review", :review],
    ["Änderungen angefordert", :blocked],
    ["Freigegeben", :done]
  ].freeze

  def up
    add_reference :tasks, :board_column, foreign_key: true
    add_column :tasks, :color, :string, null: false, default: "none"
    add_column :tasks, :archived_at, :datetime
    add_index :tasks, :archived_at
    add_index :tasks, :color

    MigrationBoard.reset_column_information
    MigrationBoardColumn.reset_column_information
    MigrationTask.reset_column_information

    MigrationBoard.find_each do |board|
      columns = {}
      TEMPLATE.each_with_index do |(name, kind), index|
        columns[kind] = MigrationBoardColumn.create!(
          board_id: board.id,
          name: name,
          kind: KIND_VALUES.fetch(kind),
          position: index + 1,
          created_at: Time.current,
          updated_at: Time.current
        )
      end

      MigrationTask.where(board_id: board.id).find_each do |task|
        _name, kind = STATUS_TO_COLUMN.fetch(task.status, STATUS_TO_COLUMN[0])
        task.update_columns(board_column_id: columns.fetch(kind).id)
      end
    end

    change_column_null :tasks, :board_column_id, false
  end

  def down
    remove_reference :tasks, :board_column, foreign_key: true
    remove_column :tasks, :color
    remove_column :tasks, :archived_at
  end
end
