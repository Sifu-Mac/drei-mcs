class PromoteFirstUserToAdminIfNeeded < ActiveRecord::Migration[8.1]
  def up
    return if User.where(admin: true).exists?

    first_user = User.order(:created_at).first
    first_user&.update_column(:admin, true)
  end

  def down
    # no-op
  end
end
