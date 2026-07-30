class CreateBoardColumns < ActiveRecord::Migration[8.1]
  def change
    create_table :board_columns do |t|
      t.references :board, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.integer :kind, null: false, default: 0
      t.timestamps
    end

    add_index :board_columns, [:board_id, :position], unique: true
    add_index :board_columns, [:board_id, :kind]
  end
end
