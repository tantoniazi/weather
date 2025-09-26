module Api
  module V1
    class WeathersController < BaseController
      def show
        if params[:zipcode].present?
          zipcode = params[:zipcode].gsub(/\D/, "")

          if zipcode.length == 8
            weather_service = WeatherService.new(zipcode, current_user)
            data = weather_service.forecast

            render json: data
          else
            render json: { error: "Zip Code must have 8 digits" }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
