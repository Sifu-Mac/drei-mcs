class PromoteFirstUserToAdminIfNeeded < ActiveRecord::Migration[8.1]
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  def up
    return if MigrationUser.where(admin: true).exists?

    first_user = MigrationUser.order(:created_at).first
    first_user&.update_column(:admin, true)
  end

  def down
    # no-op
  end
end
