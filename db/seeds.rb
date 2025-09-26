web_user = User.find_or_create_by!(email: "web@weather.com") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.confirmed_at = Time.current
  user.address = "Rua das Flores, 123"
  user.country = "Brasil"
  user.zip_code = "01310-100"
end
api_user = User.find_or_create_by!(email: "api@weather.com") do |user|
  user.password = "api123456"
  user.password_confirmation = "api123456"
  user.confirmed_at = Time.current
  user.address = "Av. Paulista, 1000"
  user.country = "Brasil"
  user.zip_code = "01310-100"
end

admin_user = User.find_or_create_by!(email: "admin@weather.com") do |user|
  user.password = "admin123"
  user.password_confirmation = "admin123"
  user.confirmed_at = Time.current
  user.address = "Rua Admin, 1"
  user.country = "Brasil"
  user.zip_code = "00000-000"
end

sample_weathers = [
  {
    zip_code: "01310100",
    temperature: 25.5,
    temp_min: 22.0,
    temp_max: 28.0,
    description: "céu limpo",
    user: web_user,
  },
  {
    zip_code: "20040020",
    temperature: 30.2,
    temp_min: 27.5,
    temp_max: 32.0,
    description: "parcialmente nublado",
    user: web_user,
  },
  {
    zip_code: "30112000",
    temperature: 18.8,
    temp_min: 15.0,
    temp_max: 22.0,
    description: "chuva leve",
    user: api_user,
  },
  {
    zip_code: "40070110",
    temperature: 26.0,
    temp_min: 24.0,
    temp_max: 29.0,
    description: "ensolarado",
    user: admin_user,
  },
]

sample_weathers.each do |weather_attrs|
  weather = Weather.find_or_create_by!(
    zip_code: weather_attrs[:zip],
    user: weather_attrs[:user],
  ) do |w|
    w.temperature = weather_attrs[:temperature]
    w.temp_min = weather_attrs[:temp_min]
    w.temp_max = weather_attrs[:temp_max]
    w.description = weather_attrs[:description]
  end
end
