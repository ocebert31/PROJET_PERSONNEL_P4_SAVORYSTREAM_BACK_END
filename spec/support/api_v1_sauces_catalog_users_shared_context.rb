# frozen_string_literal: true

# Utilisé par les request specs du catalogue sauces (catégories, conditionnements, etc.).
# Même paire admin / customer pour tous ces specs : chaque exemple RSpec tourne dans une
# transaction qui rollback, donc pas de conflit d’unicité entre fichiers.
# Surcharge seulement si un spec a besoin d’isolation (ex. plusieurs jeux d’utilisateurs).
#
#   include_context "API V1 sauces catalog admin and customer users" do
#     let(:catalog_spec_slug) { "mon-cas" }
#   end
RSpec.shared_context "API V1 sauces catalog admin and customer users" do
  let(:catalog_spec_slug) { "sauces-catalog" }
  let(:catalog_admin_phone) { "0611111100" }
  let(:catalog_customer_phone) { "0699999900" }

  let!(:admin) do
    create(
      :user, :admin,
      first_name: "Ada",
      last_name: "Admin",
      email: "ada.#{catalog_spec_slug}.admin@savorystream.dev",
      phone_number: catalog_admin_phone
    )
  end
  let!(:customer) do
    create(
      :user,
      first_name: "Chloe",
      last_name: "Customer",
      email: "chloe.#{catalog_spec_slug}.customer@savorystream.dev",
      phone_number: catalog_customer_phone
    )
  end
  let(:admin_headers) { auth_headers_for(admin) }
  let(:customer_headers) { auth_headers_for(customer) }
end
