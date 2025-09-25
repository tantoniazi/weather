class WeatherService
  include HTTParty
  base_uri "https://api.openweathermap.org/data/2.5"

  def initialize(zip, user = nil)
    @zip = zip
    @user = user
    @api_key = Rails.application.credentials.OPENWEATHER_API_KEY
  end

  def forecast
    Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      response = self.class.get("/weather", query: {
                                              zip: "#{@zip},br",
                                              units: "metric",
                                              appid: @api_key,
                                            })

      if response.success? && valid_response?(response)
        data = {
          temperature: response.dig("main", "temp"),
          temp_min: response.dig("main", "temp_min"),
          temp_max: response.dig("main", "temp_max"),
          description: response["weather"].first["description"],
          from_cache: false,
          from_database: false,
        }

        Weather.create(
          {
            zip: @zip,
            temperature: data[:temperature],
            temp_min: data[:temp_min],
            temp_max: data[:temp_max],
            description: data[:description],
            user_id: @user&.id,
          },
        )

        data
      else
        Rails.logger.warn("WeatherService: API vazia/erro para zip #{@zip}. Usando fallback do banco...")

        if (record = Weather.where(zip: @zip).last)
          {
            temperature: record.temperature,
            temp_min: record.temp_min,
            temp_max: record.temp_max,
            description: record.description,
            from_cache: false,
            from_database: true,
          }
        else
          { error: "Unable to fetch weather data" }
        end
      end
    end
  end

  def cached?
    Rails.cache.exist?(cache_key)
  end

  private

  def cache_key
    "weather/#{@zip}"
  end

  def valid_response?(response)
    response["main"].present? &&
      response["weather"].present? &&
      response["weather"].is_a?(Array) &&
      response["weather"].first.present?
  end
end
