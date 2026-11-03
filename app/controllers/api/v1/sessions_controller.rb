module Api
  module V1
    class SessionsController < ApplicationController
      skip_before_action :authenticate_user!, only: [:create]
      skip_before_action :verify_authenticity_token, only: [:create]

      # POST /api/v1/session
      def create
        user = User.find_by("LOWER(email) = ?", params[:email].to_s.strip.downcase)

        if user&.authenticate(params[:password])
          reset_session
          session[:user_id] = user.id
          render json: {
            user: {
              id: user.id,
              email: user.email,
              first_name: user.first_name,
              last_name: user.last_name,
              role: user.role
            },
            csrf_token: form_authenticity_token
          }, status: :ok
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      # GET /api/v1/session
      def show
        render json: {
          user: {
            id: current_user.id,
            email: current_user.email,
            first_name: current_user.first_name,
            last_name: current_user.last_name,
            role: current_user.role
          },
          csrf_token: form_authenticity_token
        }, status: :ok
      end

      # DELETE /api/v1/session
      def destroy
        reset_session
        head :no_content
      end
    end
  end
end
