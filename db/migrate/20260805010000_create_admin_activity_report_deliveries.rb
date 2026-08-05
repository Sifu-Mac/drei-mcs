class CreateAdminActivityReportDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_activity_report_deliveries do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :period_start_at, null: false
      t.datetime :period_end_at, null: false

      t.timestamps
    end

    add_index :admin_activity_report_deliveries, [ :user_id, :period_end_at ], unique: true, name: "index_admin_report_deliveries_on_user_and_period_end"
  end
end
