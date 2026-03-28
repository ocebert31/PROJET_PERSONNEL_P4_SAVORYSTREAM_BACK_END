# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  before { User.delete_all }

  describe "valid signup" do
    it "persists a customer with normalized email and phone" do
      user = build_user
      expect(user.save).to be true
      user.reload
      expect(user.role).to eq("customer")
      expect(user.email).to eq("jane@example.com")
      expect(user.phone_number).to eq("0612345678")
    end
  end

  describe "first_name" do
    it "rejects blank first name" do
      user = build_user(first_name: "")
      expect(user.save).to be false
      expect(user.errors[:first_name]).to be_present
    end

    it "rejects first name longer than 50 characters" do
      user = build_user(first_name: "a" * 51)
      expect(user.save).to be false
      expect(user.errors[:first_name]).to be_present
    end
  end

  describe "last_name" do
    it "rejects blank last name" do
      user = build_user(last_name: "")
      expect(user.save).to be false
      expect(user.errors[:last_name]).to be_present
    end

    it "rejects last name longer than 50 characters" do
      user = build_user(last_name: "a" * 51)
      expect(user.save).to be false
      expect(user.errors[:last_name]).to be_present
    end
  end

  describe "email" do
    it "rejects blank email" do
      user = build_user(email: "")
      expect(user.save).to be false
      expect(user.errors[:email]).to be_present
    end

    it "rejects invalid email format" do
      user = build_user(email: "not-an-email")
      expect(user.save).to be false
      expect(user.errors[:email]).to be_present
    end

    it "rejects email longer than 50 characters" do
      long_email = "#{"a" * 39}@example.com"
      expect(long_email.length).to be > 50

      user = build_user(email: long_email)
      expect(user.save).to be false
      expect(user.errors[:email]).to be_present
    end

    it "rejects duplicate email" do
      User.create!(valid_attributes.merge(email: "dup@example.com", phone_number: "0611111111"))

      user = build_user(email: "dup@example.com", phone_number: "0622222222")
      expect(user.save).to be false
      expect(user.errors[:email]).to be_present
    end

    it "normalizes email to stripped lowercase before save" do
      user = build_user(email: "  Jane@EXAMPLE.COM  ")
      expect(user.save).to be true
      expect(user.reload.email).to eq("jane@example.com")
    end
  end

  describe "phone_number" do
    it "rejects blank phone number" do
      user = build_user(phone_number: "")
      expect(user.save).to be false
      expect(user.errors[:phone_number]).to be_present
    end

    it "rejects phone number shorter than 10 digits" do
      user = build_user(phone_number: "061234567")
      expect(user.save).to be false
      expect(user.errors[:phone_number]).to be_present
    end

    it "rejects phone number longer than 10 digits" do
      user = build_user(phone_number: "06123456789")
      expect(user.save).to be false
      expect(user.errors[:phone_number]).to be_present
    end

    it "rejects phone number with non-digit characters" do
      user = build_user(phone_number: "061234567a")
      expect(user.save).to be false
      expect(user.errors[:phone_number]).to be_present
    end

    it "rejects duplicate phone number" do
      User.create!(valid_attributes.merge(email: "a@example.com", phone_number: "0611111111"))

      user = build_user(email: "b@example.com", phone_number: "0611111111")
      expect(user.save).to be false
      expect(user.errors[:phone_number]).to be_present
    end

    it "normalizes phone number by removing spaces before save" do
      user = build_user(phone_number: "06 12 34 56 78")
      expect(user.save).to be true
      expect(user.reload.phone_number).to eq("0612345678")
    end
  end

  describe "password" do
    it "rejects blank password" do
      user = build_user(password: "", password_confirmation: "")
      expect(user.save).to be false
      expect(user.errors[:password]).to be_present
    end

    it "rejects password shorter than 8 characters" do
      user = build_user(password: "short1", password_confirmation: "short1")
      expect(user.save).to be false
      expect(user.errors[:password]).to be_present
    end

    it "rejects password longer than 72 characters" do
      long = "a" * 73
      user = build_user(password: long, password_confirmation: long)
      expect(user.save).to be false
      expect(user.errors[:password]).to be_present
    end

    it "rejects password mismatch" do
      user = build_user(password: "password12", password_confirmation: "other")
      expect(user.save).to be false
      expect(user.errors[:password_confirmation]).to be_present
    end
  end

  describe "role" do
    it "accepts admin role when explicitly assigned" do
      user = build_user(
        role: :admin,
        email: "admin@example.com",
        phone_number: "0699999999"
      )
      expect(user.save).to be true
      expect(user.reload.role).to eq("admin")
    end

    it "rejects invalid role value" do
      user = build_user(email: "other@example.com", phone_number: "0688888888")
      expect { user.role = :superuser }.to raise_error(ArgumentError, /not a valid role/)
    end
  end

  def valid_attributes(overrides = {})
    {
      first_name: "Jane",
      last_name: "Doe",
      email: "jane@example.com",
      password: "password12",
      password_confirmation: "password12",
      phone_number: "0612345678"
    }.merge(overrides)
  end

  def build_user(overrides = {})
    described_class.new(valid_attributes(overrides))
  end
end
