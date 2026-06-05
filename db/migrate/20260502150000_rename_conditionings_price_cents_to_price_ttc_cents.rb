# frozen_string_literal: true

class RenameConditioningsPriceCentsToPriceTtcCents < ActiveRecord::Migration[8.1]
  def change
    remove_check_constraint :conditionings, name: "conditionings_price_cents_non_negative"
    rename_column :conditionings, :price_cents, :price_ttc_cents
    add_check_constraint :conditionings, "price_ttc_cents >= 0", name: "conditionings_price_ttc_cents_non_negative"
  end
end
