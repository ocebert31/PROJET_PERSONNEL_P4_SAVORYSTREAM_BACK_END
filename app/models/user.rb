class User < ApplicationRecord
  has_secure_password

  enum :role, { customer: "customer", admin: "admin" }, default: :customer

  before_validation :normalize_email
  before_validation :normalize_phone_number

  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  # Allow blank : pour faire remonter l'erreur sur l'absence d'email et non pas sur son format.
  validates :email, presence: true, length: { maximum: 50 }, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :phone_number, presence: true, length: { is: 10 },
            format: { with: /\A\d{10}\z/, message: "must be 10 digits" },
            uniqueness: true
  validates :password, length: { minimum: 8, maximum: 72 }, if: -> { password.present? }

  private

  def normalize_email
    self.email = email.to_s.strip.downcase if email.present?
  end

  def normalize_phone_number
    self.phone_number = phone_number.to_s.gsub(/\s+/, "") if phone_number.present?
  end
end
