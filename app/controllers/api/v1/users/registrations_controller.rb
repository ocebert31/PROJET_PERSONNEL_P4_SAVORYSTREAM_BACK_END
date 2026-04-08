# frozen_string_literal: true

module Api
  module V1
    module Users
      class RegistrationsController < ApplicationController
        def create
          @user = User.new(user_attributes)

          if @user.save
            render json: {
              message: "Inscription réussie.",
              user: UserSerializer.call(@user)
            }, status: :created
          else
            render json: { errors: @user.errors.messages }, status: :unprocessable_entity
          end
        end

        private

        # Couche métier, correspondant avec le modèle User.
        def user_attributes
          p = user_params
          {
            first_name: p[:first_name].presence || p[:firstName],
            last_name: p[:last_name].presence || p[:lastName],
            email: p[:email],
            password: p[:password],
            password_confirmation: p[:password_confirmation].presence || p[:confirmPassword],
            phone_number: p[:phone_number].presence || p[:phoneNumber],
            role: :customer
          }
        end

        # Filtre les données entrantes pour éviter les injections de code.
        def user_params
          params.permit(
            :first_name, :last_name, :email, :password, :password_confirmation, :phone_number,
            :firstName, :lastName, :confirmPassword, :phoneNumber
          )
        end
      end
    end
  end
end
