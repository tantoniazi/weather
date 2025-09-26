class WeathersController < ApplicationController
  before_action :authenticate_user!

  def index
    @weathers = current_user.weathers.order(created_at: :desc).page(params[:page]).per(10)
  end

  def search
    if params[:zipcode].present?
      zipcode = params[:zipcode].gsub(/\D/, "")

      if zipcode.length == 8
        @weather_data = WeatherService.new(zipcode, current_user).forecast
      else
        @weather_data = { error: "Zip Code must have 8 digits" }
      end
    end

    @weathers = current_user.weathers.order(created_at: :desc).page(params[:page]).per(10)

    render "weathers/index"
  end
end
