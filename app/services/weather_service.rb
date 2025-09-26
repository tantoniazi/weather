class WeatherService
  include HTTParty
  base_uri "https://api.openweathermap.org/data/2.5"

  def initialize(zip_code, user = nil)
    @zip_code = zip_code
    @user = user
    @api_key = Rails.application.credentials.OPENWEATHER_API_KEY
  end

  def forecast
    Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      request_api
    end
  end

  private

  def request_api
    viacep = HTTParty.get("https://viacep.com.br/ws/#{@zip_code}/json/")
    city = viacep["localidade"]

    response = self.class.get("/weather", query: {
                                            q: "#{city},BR",
                                            units: "metric",
                                            lang: "pt_br",
                                            appid: @api_key,
                                          })

    if response.success? && valid_response?(response)
      data = {
        temperature: response.dig("main", "temp"),
        temp_min: response.dig("main", "temp_min"),
        temp_max: response.dig("main", "temp_max"),
        description: response["weather"].first["description"],
        from_cache: true,
        from_database: false,
      }

      create_fallback_data(data)
    else
      if (record = Weather.where(zip_code: @zip_code).order(created_at: :desc).first)
        data = {
          temperature: record.temperature,
          temp_min: record.temp_min,
          temp_max: record.temp_max,
          description: record.description,
          from_cache: false,
          from_database: true,
        }
      end
    end

    data
  end

  def create_fallback_data(data)
    Weather.create(
      {
        zip_code: @zip_code,
        temperature: data[:temperature],
        temp_min: data[:temp_min],
        temp_max: data[:temp_max],
        description: data[:description],
        user_id: @user&.id,
      },
    )
  end

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
