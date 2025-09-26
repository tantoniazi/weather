module Api
  module V1
    class SessionsController < Devise::SessionsController
      respond_to :json

      private

      def respond_with(resource, _opts = {})
        render json: {
                 status: { code: 200, message: "Logged in successfully." },
                 data: resource,
               }, status: :ok
      end

      def respond_to_on_destroy
        jwt_payload = JWT.decode(request.headers["Authorization"].split(" ").last,
                                 Rails.application.credentials.devise_jwt_secret_key,
                                 true, algorithm: "HS256").first
        current_user = User.find(jwt_payload["sub"])
        render json: {
                 status: 200,
                 message: "Logged out successfully.",
               }, status: :ok
      rescue JWT::DecodeError
        render json: {
                 status: 401,
                 message: "Invalid token.",
               }, status: :unauthorized
      end
    end
  end
end
