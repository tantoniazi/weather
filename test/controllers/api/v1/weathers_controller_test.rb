require "test_helper"

class Api::V1::WeathersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should get weather data via API" do
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

    get "/api/v1/weathers/01310100"
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal 25.0, json_response["temperature"]
    assert_equal "céu limpo", json_response["description"]
    assert_equal false, json_response["from_cache"]
  end

  test "should return cached data when available" do
    weather_data = {
      temperature: 25.0,
      temp_min: 20.0,
      temp_max: 30.0,
      description: "céu limpo",
      from_cache: true,
      from_database: false,
    }

    WeatherService.any_instance.stubs(:forecast).returns(weather_data)

    get "/api/v1/weathers/01310100"
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal true, json_response["from_cache"]
  end

  test "should return database data when API fails" do
    weather_data = {
      temperature: 20.0,
      temp_min: 15.0,
      temp_max: 25.0,
      description: "nublado",
      from_cache: false,
      from_database: true,
    }

    WeatherService.any_instance.stubs(:forecast).returns(weather_data)

    get "/api/v1/weathers/01310100"
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal true, json_response["from_database"]
  end

  test "should return error when weather data is unavailable" do
    weather_data = { error: "Unable to fetch weather data" }
    WeatherService.any_instance.stubs(:forecast).returns(weather_data)

    get "/api/v1/weathers/01310100"
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal "Unable to fetch weather data", json_response["error"]
  end

  test "should require authentication for API access" do
    sign_out @user
    get "/api/v1/weathers/01310100"
    assert_redirected_to new_user_session_path
  end

  test "should handle invalid zipcode in API" do
    weather_data = { error: "CEP deve ter 8 dígitos" }
    WeatherService.any_instance.stubs(:forecast).returns(weather_data)

    get "/api/v1/weathers/123"
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal "CEP deve ter 8 dígitos", json_response["error"]
  end

  test "should return JSON format" do
    weather_data = {
      temperature: 25.0,
      temp_min: 20.0,
      temp_max: 30.0,
      description: "céu limpo",
      from_cache: false,
      from_database: false,
    }

    WeatherService.any_instance.stubs(:forecast).returns(weather_data)

    get "/api/v1/weathers/01310100"
    assert_response :success
    assert_equal "application/json; charset=utf-8", response.content_type
  end
end
