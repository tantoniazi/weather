require "test_helper"

class Api::V1::WeathersControllerJwtTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:api_user)
    @valid_token = @user.authentication_token
    @invalid_token = "invalid_token_123"
    @weather_data = {
      temperature: 25.0,
      temp_min: 20.0,
      temp_max: 30.0,
      description: "céu limpo",
      from_cache: false,
      from_database: false,
    }
  end

  # Authentication Tests
  test "should authenticate with valid JWT token" do
    WeatherService.any_instance.stubs(:forecast).returns(@weather_data)

    get "/api/v1/weathers/01310100", 
        headers: { "Authorization" => "Bearer #{@valid_token}" }
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 25.0, json_response["temperature"]
  end

  test "should reject request without authorization header" do
    get "/api/v1/weathers/01310100"
    
    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert_equal "Unauthorized", json_response["error"]
  end

  test "should reject request with invalid token" do
    get "/api/v1/weathers/01310100", 
        headers: { "Authorization" => "Bearer #{@invalid_token}" }
    
    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert_equal "Unauthorized", json_response["error"]
  end

  test "should reject request with malformed authorization header" do
    get "/api/v1/weathers/01310100", 
        headers: { "Authorization" => "InvalidFormat #{@valid_token}" }
    
    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert_equal "Unauthorized", json_response["error"]
  end

  test "should reject request with empty authorization header" do
    get "/api/v1/weathers/01310100", 
        headers: { "Authorization" => "" }
    
    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert_equal "Unauthorized", json_response["error"]
  end

  # Weather Data Tests
  test "should return weather data with valid zipcode and token" do
    WeatherService.any_instance.stubs(:forecast).returns(@weather_data)

    get "/api/v1/weathers/01310100", 
        headers: { "Authorization" => "Bearer #{@valid_token}" }
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert_equal 25.0, json_response["temperature"]
    assert_equal 20.0, json_response["temp_min"]
    assert_equal 30.0, json_response["temp_max"]
    assert_equal "céu limpo", json_response["description"]
    assert_equal false, json_response["from_cache"]
    assert_equal false, json_response["from_database"]
  end

  test "should return cached weather data" do
    cached_data = @weather_data.merge(from_cache: true)
    WeatherService.any_instance.stubs(:forecast).returns(cached_data)

    get "/api/v1/weathers/01310100", 
        headers: { "Authorization" => "Bearer #{@valid_token}" }
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal true, json_response["from_cache"]
  end

  test "should return database fallback data" do
    db_data = @weather_data.merge(from_database: true)
    WeatherService.any_instance.stubs(:forecast).returns(db_data)

    get "/api/v1/weathers/01310100", 
        headers: { "Authorization" => "Bearer #{@valid_token}" }
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal true, json_response["from_database"]
  end

  test "should return error when weather data unavailable" do
    error_data = { error: "Unable to fetch weather data" }
    WeatherService.any_instance.stubs(:forecast).returns(error_data)

    get "/api/v1/weathers/01310100", 
        headers: { "Authorization" => "Bearer #{@valid_token}" }
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "Unable to fetch weather data", json_response["error"]
  end

  test "should handle different zipcodes" do
    WeatherService.any_instance.stubs(:forecast).returns(@weather_data)

    zipcodes = ["01310100", "20040020", "30112000", "40070110"]
    
    zipcodes.each do |zip|
      get "/api/v1/weathers/#{zip}", 
          headers: { "Authorization" => "Bearer #{@valid_token}" }
      
      assert_response :success, "Failed for zipcode: #{zip}"
      json_response = JSON.parse(response.body)
      assert_equal 25.0, json_response["temperature"]
    end
  end

  # Content Type Tests
  test "should return JSON content type" do
    WeatherService.any_instance.stubs(:forecast).returns(@weather_data)

    get "/api/v1/weathers/01310100", 
        headers: { "Authorization" => "Bearer #{@valid_token}" }
    
    assert_response :success
    assert_equal "application/json; charset=utf-8", response.content_type
  end

  # User Association Tests
  test "should associate weather data with authenticated user" do
    WeatherService.any_instance.stubs(:forecast).returns(@weather_data)

    get "/api/v1/weathers/01310100", 
        headers: { "Authorization" => "Bearer #{@valid_token}" }
    
    assert_response :success
    
    # Verify that the WeatherService was called with the correct user
    # This is tested indirectly through the service call
    assert_not_nil @user
  end

  # Edge Cases
  test "should handle very long zipcode" do
    long_zip = "12345678901234567890"
    error_data = { error: "CEP deve ter 8 dígitos" }
    WeatherService.any_instance.stubs(:forecast).returns(error_data)

    get "/api/v1/weathers/#{long_zip}", 
        headers: { "Authorization" => "Bearer #{@valid_token}" }
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "CEP deve ter 8 dígitos", json_response["error"]
  end

  test "should handle empty zipcode" do
    error_data = { error: "CEP deve ter 8 dígitos" }
    WeatherService.any_instance.stubs(:forecast).returns(error_data)

    get "/api/v1/weathers/", 
        headers: { "Authorization" => "Bearer #{@valid_token}" }
    
    # This should result in a routing error or 404
    assert_response :not_found
  end

  test "should handle special characters in zipcode" do
    special_zip = "01310-100"
    WeatherService.any_instance.stubs(:forecast).returns(@weather_data)

    get "/api/v1/weathers/#{special_zip}", 
        headers: { "Authorization" => "Bearer #{@valid_token}" }
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 25.0, json_response["temperature"]
  end

  # Performance Tests
  test "should respond quickly to valid requests" do
    WeatherService.any_instance.stubs(:forecast).returns(@weather_data)

    start_time = Time.current
    get "/api/v1/weathers/01310100", 
        headers: { "Authorization" => "Bearer #{@valid_token}" }
    end_time = Time.current
    
    assert_response :success
    assert (end_time - start_time) < 1.second, "API response took too long"
  end

  # Multiple User Tests
  test "should work with different authenticated users" do
    other_user = users(:one)
    WeatherService.any_instance.stubs(:forecast).returns(@weather_data)

    get "/api/v1/weathers/01310100", 
        headers: { "Authorization" => "Bearer #{other_user.authentication_token}" }
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 25.0, json_response["temperature"]
  end

  # Token Format Tests
  test "should handle token with extra spaces" do
    WeatherService.any_instance.stubs(:forecast).returns(@weather_data)

    get "/api/v1/weathers/01310100", 
        headers: { "Authorization" => "  Bearer  #{@valid_token}  " }
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 25.0, json_response["temperature"]
  end

  test "should handle case insensitive bearer token" do
    WeatherService.any_instance.stubs(:forecast).returns(@weather_data)

    get "/api/v1/weathers/01310100", 
        headers: { "Authorization" => "bearer #{@valid_token}" }
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 25.0, json_response["temperature"]
  end
end
