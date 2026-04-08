# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

require "dotenv"
Dotenv.load(".env")

admin_email = ENV.fetch("SEED_ADMIN_EMAIL", "admin@example.com")
admin_phone = ENV.fetch("SEED_ADMIN_PHONE", "0600000000")
admin_password = ENV.fetch("SEED_ADMIN_PASSWORD", "ChangeMe123!")

admin = User.find_or_initialize_by(email: admin_email)
admin.assign_attributes(
  first_name: "Océane",
  last_name: "Bertrand",
  phone_number: admin_phone,
  role: :admin
)

# Update password when creating or when the password is explicitly configured.
force_password_update = ENV["SEED_ADMIN_PASSWORD"].present?

if admin.new_record? || admin.password_digest.blank? || force_password_update
  admin.password = admin_password
  admin.password_confirmation = admin_password
end

admin.save!
