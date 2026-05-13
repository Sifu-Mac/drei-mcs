class SetMacAsAdmin < ActiveRecord::Migration[8.1]
  def up
    User.where(email_address: "mac@digitalbackup.at").update_all(admin: true)
    User.where("email_address LIKE ?", "mcs-qa-%@example.com").update_all(admin: false)
  end

  def down
    User.where(email_address: "mac@digitalbackup.at").update_all(admin: false)
  end
end
