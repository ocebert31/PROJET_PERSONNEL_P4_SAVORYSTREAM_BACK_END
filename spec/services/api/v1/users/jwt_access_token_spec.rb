# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Users::JwtAccessToken do
  include ActiveSupport::Testing::TimeHelpers

  let(:user_id) { SecureRandom.uuid }

  describe "encode" do
    context "nominal" do
      it "returns a JWT string that decodes with the app secret and HS256" do
        token = described_class.encode(user_id)

        expect(token).to be_a(String)
        expect(token.split(".").length).to eq(3)

        decoded = JWT.decode(token, JwtConfig.secret, true, { algorithm: "HS256" }).first
        expect(decoded["sub"]).to eq(user_id)
        expect(decoded["typ"]).to eq("access")
        expect(decoded["jti"]).to be_present
      end

      it "sets exp and iat around JwtConfig.access_token TTL" do
        freeze_time do
          token = described_class.encode(user_id)
          payload = JWT.decode(token, JwtConfig.secret, true, { algorithm: "HS256" }).first

          expect(payload["iat"]).to eq(Time.current.to_i)
          expect(payload["exp"]).to eq((Time.current + JwtConfig.access_token_ttl).to_i)
        end
      end

      it "issues a unique jti on each call" do
        t1 = described_class.encode(user_id)
        t2 = described_class.encode(user_id)

        jti1 = JWT.decode(t1, JwtConfig.secret, true, { algorithm: "HS256" }).first["jti"]
        jti2 = JWT.decode(t2, JwtConfig.secret, true, { algorithm: "HS256" }).first["jti"]

        expect(jti1).not_to eq(jti2)
      end
    end
  end

  describe "decode" do
    context "nominal: token produced by encode" do
      it "returns the payload hash" do
        token = described_class.encode(user_id)

        payload = described_class.decode(token)

        expect(payload["sub"]).to eq(user_id)
        expect(payload["typ"]).to eq("access")
      end
    end

    context "when token is malformed" do
      it "returns nil" do
        expect(described_class.decode("not-a-jwt")).to be_nil
      end
    end

    context "when token signature is wrong" do
      it "returns nil" do
        token = described_class.encode(user_id)
        header, payload, sig = token.split(".")
        # Appending extra data to signature guarantees mismatch without relying on character replacement.
        tampered_sig = "#{sig}x"
        tampered = [ header, payload, tampered_sig ].join(".")

        expect(described_class.decode(tampered)).to be_nil
      end
    end

    context "when token is expired" do
      it "returns nil" do
        token = travel_to(Time.zone.parse("2026-01-01 12:00:00")) do
          described_class.encode(user_id)
        end

        travel_to Time.zone.parse("2026-01-01 13:00:00") do
          expect(described_class.decode(token)).to be_nil
        end
      end
    end
  end
end
