class RestoreApiUsageRecordsSchema < ActiveRecord::Migration[8.1]
  def up
    unless table_exists?(:api_usage_records)
      create_table :api_usage_records do |t|
        t.references :user, null: false, foreign_key: true
        t.integer :month, null: false
        t.integer :call_count, null: false, default: 0

        t.timestamps
      end
    end

    add_index :api_usage_records, :user_id unless index_exists?(:api_usage_records, :user_id)
    add_index :api_usage_records, %i[user_id month], unique: true unless index_exists?(:api_usage_records, %i[user_id month], unique: true)
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "api_usage_records may predate this repair migration"
  end
end
