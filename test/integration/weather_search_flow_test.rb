require "test_helper"

class WeatherSearchFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "complete weather search flow" do
    # 1. Acessar página inicial
    get root_url
    assert_response :success
    assert_select "h2", "Buscar Clima por CEP"
    assert_select "input[name='zipcode']"

    # 2. Fazer busca com CEP válido
    weather_data = {
      temperature: 25.0,
      temp_min: 20.0,
      temp_max: 30.0,
      description: "céu limpo",
      from_cache: false,
      from_database: false,
    }

    WeatherService.any_instance.stubs(:forecast).returns(weather_data)

    get search_weathers_url, params: { zipcode: "01310100" }
    assert_response :success

    # 3. Verificar se os dados aparecem na página
    assert_select ".weather-result"
    assert_select "h4", "Clima para CEP: 01310100"
    assert_select ".display-4", "25.0°C"
    assert_select ".text-capitalize", "céu limpo"

    # 4. Verificar se o weather foi salvo no banco
    weather = Weather.last
    assert_equal "01310100", weather.zip
    assert_equal @user.id, weather.user_id
    assert_equal 25.0, weather.temperature
  end

  test "weather search with invalid zipcode" do
    get search_weathers_url, params: { zipcode: "123" }
    assert_response :success

    # Verificar se erro aparece na página
    assert_select ".alert-danger", "CEP deve ter 8 dígitos"
  end

  test "weather search with empty zipcode" do
    get search_weathers_url, params: { zipcode: "" }
    assert_response :success

    # Página deve carregar normalmente sem dados de weather
    assert_select "h2", "Buscar Clima por CEP"
  end

  test "user can view their weather history" do
    # Criar alguns weathers para o usuário
    weather1 = Weather.create!(
      zip: "01310100",
      temperature: 25.0,
      temp_min: 20.0,
      temp_max: 30.0,
      description: "céu limpo",
      user: @user,
      created_at: 1.hour.ago,
    )

    weather2 = Weather.create!(
      zip: "04567890",
      temperature: 18.0,
      temp_min: 15.0,
      temp_max: 22.0,
      description: "nublado",
      user: @user,
      created_at: 2.hours.ago,
    )

    get root_url
    assert_response :success

    # Verificar se o histórico aparece
    assert_select ".weather-info h6", "CEP: 01310100"
    assert_select ".weather-info h6", "CEP: 04567890"
  end

  test "user cannot access other user's weather data" do
    # Criar usuário e weather para outro usuário
    other_user = User.create!(email: "other@example.com", password: "password123")
    other_weather = Weather.create!(
      zip: "99999999",
      temperature: 10.0,
      temp_min: 5.0,
      temp_max: 15.0,
      description: "frio",
      user: other_user,
    )

    # Tentar acessar weather de outro usuário
    assert_raises(ActiveRecord::RecordNotFound) do
      get weather_url(other_weather)
    end
  end

  test "authentication required for all weather operations" do
    sign_out @user

    # Tentar acessar página inicial
    get root_url
    assert_redirected_to new_user_session_path

    # Tentar fazer busca
    get search_weathers_url, params: { zipcode: "01310100" }
    assert_redirected_to new_user_session_path

    # Tentar acessar API
    get "/api/v1/weathers/01310100"
    assert_redirected_to new_user_session_path
  end

  test "weather search creates new weather record" do
    initial_count = Weather.count

    weather_data = {
      temperature: 25.0,
      temp_min: 20.0,
      temp_max: 30.0,
      description: "céu limpo",
      from_cache: false,
      from_database: false,
    }

    WeatherService.any_instance.stubs(:forecast).returns(weather_data)

    get search_weathers_url, params: { zipcode: "01310100" }

    assert_equal initial_count + 1, Weather.count

    new_weather = Weather.last
    assert_equal "01310100", new_weather.zip
    assert_equal @user.id, new_weather.user_id
    assert_equal 25.0, new_weather.temperature
    assert_equal "céu limpo", new_weather.description
  end
end
