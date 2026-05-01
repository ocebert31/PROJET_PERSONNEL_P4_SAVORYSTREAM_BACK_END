# frozen_string_literal: true

class CartSauce < ApplicationRecord
  belongs_to :cart
  belongs_to :sauce
  belongs_to :conditioning

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :conditioning_matches_sauce

  private

  def conditioning_matches_sauce
    return if conditioning.blank? || sauce.blank?

    errors.add(:conditioning_id, "does not belong to sauce") unless conditioning.sauce_id == sauce.id
  end
end
