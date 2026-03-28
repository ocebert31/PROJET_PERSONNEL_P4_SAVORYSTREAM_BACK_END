# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup { User.delete_all }

  # Valid user

  test "valid signup" do
    user = build_user
    assert user.save
    user.reload
    assert_equal "customer", user.role
    assert_equal "jane@example.com", user.email
    assert_equal "0612345678", user.phone_number
  end

  # first_name

  test "rejects blank first name" do
    user = build_user(first_name: "")
    assert_not user.save
    assert user.errors[:first_name].present?
  end

  test "rejects first name longer than 50 characters" do
    user = build_user(first_name: "a" * 51)
    assert_not user.save
    assert user.errors[:first_name].present?
  end

  # last_name

  test "rejects blank last name" do
    user = build_user(last_name: "")
    assert_not user.save
    assert user.errors[:last_name].present?
  end

  test "rejects last name longer than 50 characters" do
    user = build_user(last_name: "a" * 51)
    assert_not user.save
    assert user.errors[:last_name].present?
  end

  # email

  test "rejects blank email" do
    user = build_user(email: "")
    assert_not user.save
    assert user.errors[:email].present?
  end

  test "rejects invalid email format" do
    user = build_user(email: "not-an-email")
    assert_not user.save
    assert user.errors[:email].present?
  end

  test "rejects email longer than 50 characters" do
    long_email = "#{"a" * 39}@example.com"
    assert_operator long_email.length, :>, 50

    user = build_user(email: long_email)
    assert_not user.save
    assert user.errors[:email].present?
  end

  test "rejects duplicate email" do
    User.create!(valid_attributes.merge(email: "dup@example.com", phone_number: "0611111111"))

    user = build_user(email: "dup@example.com", phone_number: "0622222222")
    assert_not user.save
    assert user.errors[:email].present?
  end

  test "normalizes email to stripped lowercase before save" do
    user = build_user(email: "  Jane@EXAMPLE.COM  ")
    assert user.save
    assert_equal "jane@example.com", user.reload.email
  end

  # phone_number

  test "rejects blank phone number" do
    user = build_user(phone_number: "")
    assert_not user.save
    assert user.errors[:phone_number].present?
  end

  test "rejects phone number shorter than 10 digits" do
    user = build_user(phone_number: "061234567")
    assert_not user.save
    assert user.errors[:phone_number].present?
  end

  test "rejects phone number longer than 10 digits" do
    user = build_user(phone_number: "06123456789")
    assert_not user.save
    assert user.errors[:phone_number].present?
  end

  test "rejects phone number with non-digit characters" do
    user = build_user(phone_number: "061234567a")
    assert_not user.save
    assert user.errors[:phone_number].present?
  end

  test "rejects duplicate phone number" do
    User.create!(valid_attributes.merge(email: "a@example.com", phone_number: "0611111111"))

    user = build_user(email: "b@example.com", phone_number: "0611111111")
    assert_not user.save
    assert user.errors[:phone_number].present?
  end

  test "normalizes phone number by removing spaces before save" do
    user = build_user(phone_number: "06 12 34 56 78")
    assert user.save
    assert_equal "0612345678", user.reload.phone_number
  end

  # password (length + has_secure_password)

  test "rejects blank password" do
    user = build_user(password: "", password_confirmation: "")
    assert_not user.save
    assert user.errors[:password].present?
  end

  test "rejects password shorter than 8 characters" do
    user = build_user(password: "short1", password_confirmation: "short1")
    assert_not user.save
    assert user.errors[:password].present?
  end

  test "rejects password longer than 72 characters" do
    long = "a" * 73
    user = build_user(password: long, password_confirmation: long)
    assert_not user.save
    assert user.errors[:password].present?
  end

  test "rejects password mismatch" do
    user = build_user(password: "password12", password_confirmation: "other")
    assert_not user.save
    assert user.errors[:password_confirmation].present?
  end

  # role

  test "accepts admin role when explicitly assigned" do
    user = build_user(
      role: :admin,
      email: "admin@example.com",
      phone_number: "0699999999"
    )
    assert user.save
    assert_equal "admin", user.reload.role
  end

  test "rejects invalid role value" do
    user = build_user(email: "other@example.com", phone_number: "0688888888")
    assert_raises(ArgumentError, match: /not a valid role/) do
      user.role = :superuser
    end
  end

  private

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
    User.new(valid_attributes(overrides))
  end
end
