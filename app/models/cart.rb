# frozen_string_literal: true

class Cart < ApplicationRecord
  belongs_to :user, optional: true

  has_many :cart_sauces, dependent: :destroy
  has_many :sauces, through: :cart_sauces

  validates :guest_id, uniqueness: true, allow_nil: true
  validate :exactly_one_owner

  private

  def exactly_one_owner
    owner_user = user.present? || user_id.present?
    owner_guest = guest_id.present?

    return if owner_user ^ owner_guest

    errors.add(:base, "cart must belong to either a user or a guest")
  end
end
