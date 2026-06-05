# frozen_string_literal: true

# Ce fichier s'exécute au démarrage de Rails et définit
# le marché par défaut du serveur : celui utilisé lorsque le client n'envoie pas de région exploitable dans Accept-Language.

alpha2 = ENV.fetch("DEFAULT_MARKET_COUNTRY_ALPHA2", "FR").to_s.strip.upcase
alpha2 = "FR" unless alpha2.match?(/\A[A-Z]{2}\z/)

Rails.application.config.x.default_market_country_alpha2 = alpha2
