json.extract! weather, :id, :temperature, :temp_min, :temp_max, :description, :created_at, :updated_at
json.url weather_url(weather, format: :json)
