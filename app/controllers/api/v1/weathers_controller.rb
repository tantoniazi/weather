module Api
  module V1
    class WeathersController < ApplicationController
      def show
        zip = params[:zip]

        weather_service = WeatherService.new(zip)
        data = weather_service.forecast

        if weather_service.cached?
          data[:from_cache] = true
        end

        render json: data
      end
    end
  end
end
