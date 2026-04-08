# frozen_string_literal: true

module Api
  module V1
    module Sauces
      # Après `attach`, ne pas refaire un `find` ni un Preloader sur `image_attachment` : le cache de
      # requêtes peut renvoyer un jeu vide et écraser l’association. On renvoie l’instance courante.
      class SauceReloader
        def self.with_includes!(sauce_or_id)
          if sauce_or_id.is_a?(Sauce)
            sauce_or_id
          else
            ActiveRecord::Base.uncached do
              Sauce.includes(:category, :stock, :conditionings, :ingredients)
                   .preload(image_attachment: :blob)
                   .find(sauce_or_id)
            end
          end
        end
      end
    end
  end
end
