# frozen_string_literal: true

# Une ligne = une session longue durée (refresh token) pour un utilisateur : empreinte du jeton en base,
# jeton brut uniquement côté client. Permet révocation et durée variable (remember_me).
class UsersAuthentification < ApplicationRecord
  self.table_name = "users_authentification"

  belongs_to :user, inverse_of: :users_authentications

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :not_expired, -> { where("expires_at > ?", Time.current) }
  scope :not_revoked, -> { where(revoked_at: nil) }

  # Retrouve l'enregistrement si le jeton brut correspond à l'empreinte et est encore valide.
  def self.find_valid(raw_token)
    return if raw_token.blank?

    digest = digest_for(raw_token)
    not_expired.not_revoked.find_by(token_digest: digest)
  end

  # Génère un refresh aléatoire, persiste son digest + métadonnées, retourne [jeton_brut, enregistrement] pour le JSON.
  def self.create_for_user!(user, remember_me:)
    raw = SecureRandom.urlsafe_base64(48)
    ttl = JwtConfig.refresh_token_ttl_for(remember_me)
    record = create!(
      user: user,
      token_digest: digest_for(raw),
      expires_at: ttl.from_now,
      remember_me: remember_me
    )
    [ raw, record ]
  end

  # Empreinte SHA-256 : jamais stocker le jeton en clair en base.
  def self.digest_for(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end

  # Invalide ce refresh pour les prochains appels (find_valid / refresh / revoke).
  def revoke!
    update!(revoked_at: Time.current)
  end
end
