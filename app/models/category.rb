# frozen_string_literal: true

class Category < ApplicationRecord
  has_many :sauces, dependent: :restrict_with_exception

  validates :name, presence: true, length: { maximum: 50 }, uniqueness: true
end
