class SetMacAsAdmin < ActiveRecord::Migration[8.1]
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  def up
    MigrationUser.where(email_address: "mac@digitalbackup.at").update_all(admin: true)
    MigrationUser.where("email_address LIKE ?", "mcs-qa-%@example.com").update_all(admin: false)
  end

  def down
    MigrationUser.where(email_address: "mac@digitalbackup.at").update_all(admin: false)
  end
end
