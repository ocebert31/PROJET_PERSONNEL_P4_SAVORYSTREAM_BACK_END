# frozen_string_literal: true

class CreateCartSauces < ActiveRecord::Migration[8.1]
  def change
    create_table :cart_sauces, id: :uuid do |t|
      t.integer :quantity, null: false
      t.decimal :price, null: false, precision: 10, scale: 2
      t.references :cart, type: :uuid, null: false, foreign_key: true
      t.references :sauce, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end

    add_check_constraint :cart_sauces, "quantity > 0", name: "cart_sauces_quantity_positive"
    add_check_constraint :cart_sauces, "price >= 0", name: "cart_sauces_price_non_negative"
    add_index :cart_sauces, [ :cart_id, :sauce_id ], unique: true
  end
end
