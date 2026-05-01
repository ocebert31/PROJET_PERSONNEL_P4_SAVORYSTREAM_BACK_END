# frozen_string_literal: true

module Api
  module V1
    module Carts
      class GuestCartTransferService
        def initialize(user:, guest_id:)
          @user = user
          @guest_id = guest_id
        end

        def call
          return false if @guest_id.blank?
          return false unless guest_cart

          Cart.transaction do
            replace_user_cart_if_needed!
            attach_guest_cart_to_user!
          end

          true
        end

        private

        def guest_cart
          @guest_cart ||= Cart.find_by(guest_id: @guest_id)
        end

        def replace_user_cart_if_needed!
          return unless @user.cart
          return if @user.cart.id == guest_cart.id

          @user.cart.destroy!
        end

        def attach_guest_cart_to_user!
          guest_cart.update!(user: @user, guest_id: nil)
        end
      end
    end
  end
end
