# frozen_string_literal: true

class AddGuestIdToCarts < ActiveRecord::Migration[8.1]
  def change
    add_column :carts, :guest_id, :string
    change_column_null :carts, :user_id, true

    add_index :carts, :guest_id, unique: true, where: "guest_id IS NOT NULL"
    add_check_constraint :carts,
                         "(user_id IS NOT NULL AND guest_id IS NULL) OR (user_id IS NULL AND guest_id IS NOT NULL)",
                         name: "carts_user_id_xor_guest_id"
  end
end
