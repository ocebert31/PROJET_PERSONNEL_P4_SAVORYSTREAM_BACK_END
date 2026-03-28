class ChangeUsersRoleToString < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :role_tmp, :string, null: false, default: "customer"

    execute <<-SQL.squish
      UPDATE users SET role_tmp = CASE role
        WHEN 0 THEN 'customer'
        WHEN 1 THEN 'admin'
        ELSE 'customer'
      END
    SQL

    remove_column :users, :role
    rename_column :users, :role_tmp, :role
  end

  def down
    add_column :users, :role_tmp, :integer, null: false, default: 0

    execute <<-SQL.squish
      UPDATE users SET role_tmp = CASE role
        WHEN 'customer' THEN 0
        WHEN 'admin' THEN 1
        ELSE 0
      END
    SQL

    remove_column :users, :role
    rename_column :users, :role_tmp, :role
  end
end
