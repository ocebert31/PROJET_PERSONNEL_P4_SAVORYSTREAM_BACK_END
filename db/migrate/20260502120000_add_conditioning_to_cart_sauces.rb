# frozen_string_literal: true

class AddConditioningToCartSauces < ActiveRecord::Migration[8.1]
  def up
    add_reference :cart_sauces, :conditioning, type: :uuid, foreign_key: true, null: true

    execute <<-SQL.squish
      UPDATE cart_sauces
      SET conditioning_id = (
        SELECT c.id FROM conditionings c
        WHERE c.sauce_id = cart_sauces.sauce_id
        ORDER BY c.price ASC, c.id ASC
        LIMIT 1
      )
    SQL

    execute "DELETE FROM cart_sauces WHERE conditioning_id IS NULL"

    remove_index :cart_sauces,
                 column: [ :cart_id, :sauce_id ],
                 name: "index_cart_sauces_on_cart_id_and_sauce_id"

    add_index :cart_sauces,
              [ :cart_id, :conditioning_id ],
              unique: true,
              name: "index_cart_sauces_on_cart_id_and_conditioning_id_unique"

    change_column_null :cart_sauces, :conditioning_id, false
  end

  def down
    change_column_null :cart_sauces, :conditioning_id, true

    remove_index :cart_sauces,
                 name: "index_cart_sauces_on_cart_id_and_conditioning_id_unique"

    add_index :cart_sauces,
              [ :cart_id, :sauce_id ],
              unique: true,
              name: "index_cart_sauces_on_cart_id_and_sauce_id"

    remove_reference :cart_sauces, :conditioning, foreign_key: true
  end
end
