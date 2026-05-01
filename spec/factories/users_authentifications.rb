# frozen_string_literal: true

FactoryBot.define do
  factory :users_authentification, class: "UsersAuthentification" do
    user
    token_digest { SecureRandom.hex(32) }
    expires_at { 7.days.from_now }
    remember_me { false }
  end
end
