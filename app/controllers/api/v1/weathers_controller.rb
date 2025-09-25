module Api
  module V1
    class WeathersController < ApplicationController
      before_action :authenticate_user!

      def show
        zip = params[:zip]

        weather_service = WeatherService.new(zip, current_user)
        data = weather_service.forecast

        if weather_service.cached?
          data[:from_cache] = true
        end

        render json: data
      end
    end
  end
end
