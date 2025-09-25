class WeathersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_weather, only: %i[ show edit update destroy ]

  # GET /weathers or /weathers.json
  def index
    @weathers = current_user.weathers.order(created_at: :desc).page(params[:page]).per(10)
  end

  # GET /weathers/search
  def search
    if params[:zipcode].present?
      zipcode = params[:zipcode].gsub(/\D/, "") # Remove caracteres não numéricos

      if zipcode.length == 8
        @weather_data = WeatherService.new(zipcode, current_user).forecast
      else
        @weather_data = { error: "CEP deve ter 8 dígitos" }
      end
    end

    render "home/index"
  end

  # GET /weathers/1 or /weathers/1.json
  def show
  end

  # GET /weathers/new
  def new
    @weather = Weather.new
  end

  # GET /weathers/1/edit
  def edit
  end

  # POST /weathers or /weathers.json
  def create
    @weather = Weather.new(weather_params)

    respond_to do |format|
      if @weather.save
        format.html { redirect_to @weather, notice: "Weather was successfully created." }
        format.json { render :show, status: :created, location: @weather }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @weather.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /weathers/1 or /weathers/1.json
  def update
    respond_to do |format|
      if @weather.update(weather_params)
        format.html { redirect_to @weather, notice: "Weather was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @weather }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @weather.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /weathers/1 or /weathers/1.json
  def destroy
    @weather.destroy!

    respond_to do |format|
      format.html { redirect_to weathers_path, notice: "Weather was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_weather
    @weather = current_user.weathers.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def weather_params
    params.expect(weather: [:temperature, :temp_min, :temp_max, :description])
  end
end
