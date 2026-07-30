class MakeMaxAnAdmin < ActiveRecord::Migration[8.1]
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  def up
    MigrationUser.where(email_address: "max@mx.works").update_all(admin: true)
  end

  def down
    MigrationUser.where(email_address: "max@mx.works").update_all(admin: false)
  end
end
