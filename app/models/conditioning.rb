# frozen_string_literal: true

class Conditioning < ApplicationRecord
  belongs_to :sauce

  validates :volume, presence: true, length: { maximum: 20 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
