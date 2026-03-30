# frozen_string_literal: true

require "rails_helper"

RSpec.describe UsersAuthentification, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:password) { "password12" }

  let!(:user) do
    User.create!(
      first_name: "Jane",
      last_name: "Doe",
      email: "jane@example.com",
      phone_number: "0612345678",
      password: password,
      password_confirmation: password
    )
  end

  before { described_class.delete_all }

  describe "valid persisted refresh session" do
    it "creates a digest-backed row, 7-day expiry, and resolves the raw token via find_valid" do
      raw, record = described_class.create_for_user!(user, remember_me: false)

      expect(raw).to be_present
      expect(record).to be_persisted
      expect(record.user_id).to eq(user.id)
      expect(record.remember_me).to be false
      expect(record.token_digest).to eq(described_class.digest_for(raw))
      expect(record.token_digest).not_to include(raw[0..10])
      expect(record.expires_at).to be_within(2.seconds).of(7.days.from_now)
      expect(described_class.find_valid(raw)).to eq(record)
    end
  end

  describe "validations" do
    it "rejects duplicate token_digest" do
      _raw, first = described_class.create_for_user!(user, remember_me: false)
      digest = first.token_digest

      duplicate = described_class.new(
        user: user,
        token_digest: digest,
        expires_at: 7.days.from_now,
        remember_me: false
      )

      expect(duplicate.save).to be false
      expect(duplicate.errors[:token_digest]).to be_present
    end

    it "rejects missing token_digest" do
      row = described_class.new(
        user: user,
        token_digest: nil,
        expires_at: 7.days.from_now,
        remember_me: false
      )

      expect(row.save).to be false
      expect(row.errors[:token_digest]).to be_present
    end

    it "rejects missing expires_at" do
      row = described_class.new(
        user: user,
        token_digest: "a" * 64,
        expires_at: nil,
        remember_me: false
      )

      expect(row.save).to be false
      expect(row.errors[:expires_at]).to be_present
    end
  end

  describe "scopes" do
    let!(:fresh_record) do
      _raw, rec = described_class.create_for_user!(user, remember_me: false)
      rec
    end

    it "not_expired excludes past expires_at" do
      _raw, expired = described_class.create_for_user!(user, remember_me: false)
      expired.update_column(:expires_at, 1.day.ago)

      ids = described_class.not_expired.pluck(:id)

      expect(ids).to include(fresh_record.id)
      expect(ids).not_to include(expired.id)
    end

    it "not_revoked excludes rows with revoked_at set" do
      _raw, revoked = described_class.create_for_user!(user, remember_me: false)
      revoked.update_column(:revoked_at, Time.current)

      ids = described_class.not_revoked.pluck(:id)

      expect(ids).to include(fresh_record.id)
      expect(ids).not_to include(revoked.id)
    end
  end

  describe "find_valid" do
    it "returns the record when the raw token matches a valid row" do
      raw, record = described_class.create_for_user!(user, remember_me: false)

      found = described_class.find_valid(raw)

      expect(found).to eq(record)
    end

    it "returns nil when raw token is nil" do
      expect(described_class.find_valid(nil)).to be_nil
    end

    it "returns nil when raw token is blank" do
      expect(described_class.find_valid("")).to be_nil
    end

    it "returns nil when the token does not match any digest" do
      described_class.create_for_user!(user, remember_me: false)

      expect(described_class.find_valid("totally-wrong-token")).to be_nil
    end

    it "returns nil when the row is expired" do
      raw, record = described_class.create_for_user!(user, remember_me: false)
      record.update_column(:expires_at, 1.minute.ago)

      expect(described_class.find_valid(raw)).to be_nil
    end

    it "returns nil when the row is revoked" do
      raw, record = described_class.create_for_user!(user, remember_me: false)
      record.revoke!

      expect(described_class.find_valid(raw)).to be_nil
    end
  end

  describe "create_for_user!" do
    context "when remember_me is true" do
      it "sets expires_at within the long TTL window (30 days)" do
        _raw, record = described_class.create_for_user!(user, remember_me: true)

        expect(record.remember_me).to be true
        expect(record.expires_at).to be_within(2.seconds).of(30.days.from_now)
      end
    end

    it "creates distinct raw tokens on successive calls" do
      raw1, = described_class.create_for_user!(user, remember_me: false)
      raw2, = described_class.create_for_user!(user, remember_me: false)

      expect(raw1).not_to eq(raw2)
      expect(described_class.count).to eq(2)
    end
  end

  describe "digest_for" do
    it "returns the SHA256 hex digest" do
      expect(described_class.digest_for("secret")).to eq(Digest::SHA256.hexdigest("secret"))
    end
  end

  describe "revoke!" do
    it "sets revoked_at" do
      _raw, record = described_class.create_for_user!(user, remember_me: false)
      freeze_time do
        record.revoke!
        expect(record.reload.revoked_at).to eq(Time.current)
      end
    end
  end
end
