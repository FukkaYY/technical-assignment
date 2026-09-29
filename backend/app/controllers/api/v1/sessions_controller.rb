module Api
  module V1
    class SessionsController < ApplicationController
      before_action :require_authentication, only: %i[show destroy]
      rate_limit to: 5, within: 1.minute, only: :create, with: :render_rate_limited

      def create
        credentials = session_params
        user = User.authenticate_by(
          email: credentials[:email].to_s.strip.downcase,
          role: credentials[:role],
          password: credentials[:password]
        )

        unless user
          render json: {
            errors: [{
              field: "base",
              code: "invalid_credentials",
              message: "メールアドレスまたはパスワードが正しくありません"
            }]
          }, status: :unauthorized
          return
        end

        reset_session
        session[:user_id] = user.id
        render json: { data: authenticated_user_json(user) }
      end

      def show
        render json: { data: authenticated_user_json(current_user) }
      end

      def destroy
        reset_session
        head :no_content
      end

      private

      def session_params
        params.require(:session).permit(:email, :password, :role)
      end

      def render_rate_limited
        render json: {
          errors: [{ field: "base", code: "rate_limited", message: "ログイン試行が多すぎます。しばらく待ってから再度お試しください" }]
        }, status: :too_many_requests
      end
    end
  end
end
