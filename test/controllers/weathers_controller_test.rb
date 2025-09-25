require "test_helper"

class WeathersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @weather = weathers(:one)
    @weather.update!(user: @user) # Associar weather ao usuário
    sign_in @user
  end

  test "should get index" do
    get weathers_url
    assert_response :success
  end

  test "should get new" do
    get new_weather_url
    assert_response :success
  end

  test "should create weather" do
    assert_difference("Weather.count") do
      post weathers_url, params: { weather: { description: @weather.description, temp_max: @weather.temp_max, temp_min: @weather.temp_min, temperature: @weather.temperature } }
    end

    assert_redirected_to weather_url(Weather.last)
  end

  test "should show weather" do
    get weather_url(@weather)
    assert_response :success
  end

  test "should get edit" do
    get edit_weather_url(@weather)
    assert_response :success
  end

  test "should update weather" do
    patch weather_url(@weather), params: { weather: { description: @weather.description, temp_max: @weather.temp_max, temp_min: @weather.temp_min, temperature: @weather.temperature } }
    assert_redirected_to weather_url(@weather)
  end

  test "should destroy weather" do
    assert_difference("Weather.count", -1) do
      delete weather_url(@weather)
    end

    assert_redirected_to weathers_url
  end

  test "should redirect to login when not authenticated" do
    sign_out @user
    get weathers_url
    assert_redirected_to new_user_session_path
  end

  test "should only show user's own weathers" do
    # Criar weather para outro usuário
    other_user = User.create!(email: "other@example.com", password: "password123")
    other_weather = Weather.create!(
      zip: "99999999",
      temperature: 10.0,
      temp_min: 5.0,
      temp_max: 15.0,
      description: "frio",
      user: other_user,
    )

    get weathers_url
    assert_response :success

    # Verificar que apenas o weather do usuário logado aparece
    assert_select "div", { count: 1, text: /#{@weather.zip}/ }
    assert_select "div", { count: 0, text: /#{other_weather.zip}/ }
  end

  test "should get search page" do
    get search_weathers_url
    assert_response :success
    assert_template "home/index"
  end

  test "should search weather with valid zipcode" do
    # Mock do WeatherService
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
    assert_template "home/index"
  end

  test "should handle invalid zipcode in search" do
    get search_weathers_url, params: { zipcode: "123" }
    assert_response :success
    assert_template "home/index"
  end

  test "should handle empty zipcode in search" do
    get search_weathers_url, params: { zipcode: "" }
    assert_response :success
    assert_template "home/index"
  end

  test "should not allow access to other user's weather" do
    other_user = User.create!(email: "other@example.com", password: "password123")
    other_weather = Weather.create!(
      zip: "99999999",
      temperature: 10.0,
      temp_min: 5.0,
      temp_max: 15.0,
      description: "frio",
      user: other_user,
    )

    assert_raises(ActiveRecord::RecordNotFound) do
      get weather_url(other_weather)
    end
  end
end
