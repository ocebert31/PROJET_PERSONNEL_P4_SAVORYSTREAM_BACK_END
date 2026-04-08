# frozen_string_literal: true

class Sauce < ApplicationRecord
  has_one_attached :image

  # Une sauce appartient à une catégorie car la table `sauces` porte la clé étrangère `category_id`
  # (créée via `t.references :category ...` dans la migration). Une catégorie peut donc avoir plusieurs sauces.
  belongs_to :category

  # Relation 1–1 : la table `stocks` porte `sauce_id` (FK + index unique), donc une sauce a un seul stock.
  has_one :stock, dependent: :destroy
  has_many :conditionings, dependent: :destroy
  has_many :ingredients, dependent: :destroy

  accepts_nested_attributes_for :stock, update_only: true
  accepts_nested_attributes_for :conditionings
  accepts_nested_attributes_for :ingredients

  validates :name, presence: true, length: { maximum: 50 }, uniqueness: true
  validates :tagline, presence: true, length: { maximum: 120 }
  validates :characteristic, length: { maximum: 255 }, allow_blank: true
  validates :is_available, inclusion: { in: [ true, false ] }
end
