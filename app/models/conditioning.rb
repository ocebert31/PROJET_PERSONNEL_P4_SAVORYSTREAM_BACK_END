# frozen_string_literal: true

# Prix conditionnement affiché TTC pour le client : montant **en centimes d’euro** dans `price_ttc_cents`.
# Ex. **9_99 € TTC** ⇒ **`price_ttc_cents # => 999`**
class Conditioning < ApplicationRecord
  belongs_to :sauce

  validates :volume, presence: true, length: { maximum: 20 }
  validates :price_ttc_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # API / nested attributes encore en **euros TTC** (ex. `"9.99"`), converti ⇄ **`price_ttc_cents`**.
  def price
    return nil if price_ttc_cents.nil?

    BigDecimal(price_ttc_cents) / 100
  end

  def price=(value)
    if value.nil? || (value.respond_to?(:blank?) && value.blank?)
      self.price_ttc_cents = nil
      return
    end

    euros_ttc = BigDecimal(value.to_s)
    self.price_ttc_cents = (euros_ttc * 100).round(0).to_int
  rescue ArgumentError, TypeError
    self.price_ttc_cents = nil
  end
end
