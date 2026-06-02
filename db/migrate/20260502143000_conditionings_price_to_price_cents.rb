# frozen_string_literal: true

class ConditioningsPriceToPriceCents < ActiveRecord::Migration[8.1]
  def up
    add_column :conditionings, :price_cents, :integer
    execute <<-SQL.squish
      UPDATE conditionings
      SET price_cents = ROUND((price::numeric) * 100)::integer
    SQL
    change_column_null :conditionings, :price_cents, false
    remove_column :conditionings, :price
    add_check_constraint :conditionings, "price_cents >= 0", name: "conditionings_price_cents_non_negative"
  end

  def down
    remove_check_constraint :conditionings, name: "conditionings_price_cents_non_negative"
    add_column :conditionings, :price, :decimal, precision: 10, scale: 2, null: true
    execute <<-SQL.squish
      UPDATE conditionings SET price = (price_cents::numeric / 100)
    SQL
    change_column_null :conditionings, :price, false
    remove_column :conditionings, :price_cents
  end
end
