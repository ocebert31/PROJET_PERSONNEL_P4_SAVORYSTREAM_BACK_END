# frozen_string_literal: true

require "rails_helper"

RSpec.describe Category, type: :model do
  before do
    Sauce.delete_all
    Category.delete_all
  end

  describe "valid category" do
    it "persists a category with a name" do
      category = build(:category, name: "Piquantes")

      expect(category.save).to be true
      category.reload
      expect(category.name).to eq("Piquantes")
    end
  end

  describe "name" do
    it "rejects blank name" do
      category = build(:category, name: "")
      expect(category.save).to be false
      expect(category.errors[:name]).to be_present
    end

    it "rejects name longer than 50 characters" do
      category = build(:category, name: "a" * 51)
      expect(category.save).to be false
      expect(category.errors[:name]).to be_present
    end

    it "accepts name exactly 50 characters" do
      category = build(:category, name: "a" * 50)
      expect(category.save).to be true
      expect(category.reload.name.length).to eq(50)
    end

    it "rejects duplicate name" do
      create(:category, name: "UniqueName")

      category = build(:category, name: "UniqueName")
      expect(category.save).to be false
      expect(category.errors[:name]).to be_present
    end
  end

  describe "associations" do
    it "has many sauces" do
      category = create(:category)
      create(:sauce, name: "Sauce A", tagline: "First.", category: category)
      create(:sauce, name: "Sauce B", tagline: "Second.", category: category)

      expect(category.sauces.count).to eq(2)
      expect(category.sauces.pluck(:name)).to contain_exactly("Sauce A", "Sauce B")
    end

    it "raises when destroying a category that still has sauces" do
      category = create(:category)
      create(:sauce, name: "Bound", tagline: "Tag.", category: category)

      expect { category.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
    end

    it "allows destroy when the category has no sauces" do
      category = create(:category)

      expect { category.destroy! }.not_to raise_error
      expect(described_class.find_by(id: category.id)).to be_nil
    end
  end
end
