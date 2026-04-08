# frozen_string_literal: true

class Ingredient < ApplicationRecord
  belongs_to :sauce

  validates :name, presence: true, length: { maximum: 100 }
  validates :quantity, presence: true, length: { maximum: 100 }
end
