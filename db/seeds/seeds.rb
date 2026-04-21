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

SEED_IMAGES_DIR = Rails.root.join("db", "seeds", "images")

def find_seed_image_path(filename:, sauce_name:)
  explicit_path = SEED_IMAGES_DIR.join(filename)
  return explicit_path if File.exist?(explicit_path)

  sauce_slug = sauce_name.to_s.parameterize
  candidates = Dir.glob(SEED_IMAGES_DIR.join("#{sauce_slug}.*").to_s)
  return Pathname.new(candidates.first) if candidates.any?

  nil
end

connection = ActiveRecord::Base.connection
required_tables_for_sauces_seed = %w[categories sauces stocks conditionings ingredients]

sauces_seed_data = [
  {
    name: "Smoked Ember",
    tagline: "Fumee bois et pointe sucree",
    description: "Sauce barbecue fumee ideale pour burgers, ribs et legumes rotis.",
    characteristic: "Fumee",
    is_available: true,
    category_key: :smoky,
    image_filename: "smoked-ember.jpg",
    stock_quantity: 60,
    conditionings: [
      { volume: "250ml", price: 5.90 },
      { volume: "500ml", price: 9.90 }
    ],
    ingredients: [
      { name: "Tomate", quantity: "62%" },
      { name: "Sucre de canne", quantity: "18%" },
      { name: "Paprika fume", quantity: "2%" }
    ]
  },
  {
    name: "Volcano Kick",
    tagline: "Piment franc, finale longue",
    description: "Sauce pimentee pour amateurs de chaleur, parfaite avec poulet et tacos.",
    characteristic: "Piquante",
    is_available: true,
    category_key: :spicy,
    image_filename: "./images/volcano-kick.jpg",
    stock_quantity: 45,
    conditionings: [
      { volume: "100ml", price: 4.20 },
      { volume: "250ml", price: 7.80 }
    ],
    ingredients: [
      { name: "Puree de piment", quantity: "35%" },
      { name: "Vinaigre", quantity: "14%" },
      { name: "Ail", quantity: "3%" }
    ]
  },
  {
    name: "Honey Heat",
    tagline: "Miel doux, chaleur equilibree",
    description: "Sauce sucree-salee avec un kick modere, agreable en glaze ou dip.",
    characteristic: "Doux-piquant",
    is_available: true,
    category_key: :sweet,
    image_filename: "garlic-umami.jpg",
    stock_quantity: 72,
    conditionings: [
      { volume: "250ml", price: 6.40 },
      { volume: "750ml", price: 15.50 }
    ],
    ingredients: [
      { name: "Miel", quantity: "28%" },
      { name: "Tomate", quantity: "25%" },
      { name: "Piment rouge", quantity: "4%" }
    ]
  },
  {
    name: "Garlic Umami",
    tagline: "Ail roti et profondeur umami",
    description: "Sauce savoureuse et ronde, top sur viandes grillees et pommes de terre.",
    characteristic: "Aillee",
    is_available: false,
    category_key: :smoky,
    image_filename: "honey-heat.jpg",
    stock_quantity: 0,
    conditionings: [
      { volume: "250ml", price: 5.50 }
    ],
    ingredients: [
      { name: "Ail roti", quantity: "22%" },
      { name: "Sauce soja", quantity: "8%" },
      { name: "Champignon", quantity: "6%" }
    ]
  }
]

missing_tables = required_tables_for_sauces_seed.reject { |table_name| connection.data_source_exists?(table_name) }

if missing_tables.any?
  puts "Skipping sauces seed: missing tables #{missing_tables.join(', ')}. Run `bin/rails db:migrate` first."
else
  categories_by_key = {
    smoky: Category.find_or_create_by!(name: "Fumees"),
    spicy: Category.find_or_create_by!(name: "Epicees"),
    sweet: Category.find_or_create_by!(name: "Sucrees-salees")
  }

  sauces_seed_data.each do |seed|
    sauce = Sauce.find_or_initialize_by(name: seed[:name])
    sauce.assign_attributes(
      tagline: seed[:tagline],
      description: seed[:description],
      characteristic: seed[:characteristic],
      is_available: seed[:is_available],
      category: categories_by_key.fetch(seed[:category_key])
    )
    sauce.save!

    sauce.stock&.destroy
    sauce.create_stock!(quantity: seed[:stock_quantity])

    sauce.conditionings.destroy_all
    seed[:conditionings].each do |conditioning_data|
      sauce.conditionings.create!(
        volume: conditioning_data[:volume],
        price: conditioning_data[:price]
      )
    end

    sauce.ingredients.destroy_all
    seed[:ingredients].each do |ingredient_data|
      sauce.ingredients.create!(
        name: ingredient_data[:name],
        quantity: ingredient_data[:quantity]
      )
    end

    image_filename = seed[:image_filename].to_s
    next if image_filename.blank?

    image_path = find_seed_image_path(filename: image_filename, sauce_name: sauce.name)
    unless image_path
      puts "Seed image missing for #{sauce.name}. Expected #{image_filename} or #{sauce.name.parameterize}.* in #{SEED_IMAGES_DIR}"
      next
    end

    sauce.image.purge if sauce.image.attached?
    sauce.image.attach(
      io: File.open(image_path),
      filename: image_filename,
      content_type: Marcel::MimeType.for(Pathname.new(image_path), name: image_filename)
    )
  end
end
