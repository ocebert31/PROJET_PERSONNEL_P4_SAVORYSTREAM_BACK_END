# frozen_string_literal: true

class Stock < ApplicationRecord
  belongs_to :sauce

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
