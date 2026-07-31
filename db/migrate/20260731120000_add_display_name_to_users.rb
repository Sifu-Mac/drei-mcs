class AddDisplayNameToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :display_name, :string
    add_index :users, "LOWER(display_name)", unique: true, where: "display_name IS NOT NULL", name: "index_users_on_lower_display_name"
  end
end
