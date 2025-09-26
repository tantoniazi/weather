require "test_helper"

class Api::V1::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:api_user)
    @valid_credentials = {
      user: {
        email: @user.email,
        password: "api123456"
      }
    }
    @invalid_credentials = {
      user: {
        email: @user.email,
        password: "wrongpassword"
      }
    }
  end

  # Login Tests
  test "should login with valid credentials" do
    post "/api/v1/login", params: @valid_credentials, as: :json
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert_equal 200, json_response["status"]["code"]
    assert_equal "Logged in successfully.", json_response["status"]["message"]
    assert_equal @user.email, json_response["data"]["email"]
  end

  test "should reject login with invalid password" do
    post "/api/v1/login", params: @invalid_credentials, as: :json
    
    assert_response :unauthorized
  end

  test "should reject login with invalid email" do
    invalid_email_credentials = {
      user: {
        email: "nonexistent@example.com",
        password: "password123"
      }
    }
    
    post "/api/v1/login", params: invalid_email_credentials, as: :json
    
    assert_response :unauthorized
  end

  test "should reject login with empty credentials" do
    empty_credentials = {
      user: {
        email: "",
        password: ""
      }
    }
    
    post "/api/v1/login", params: empty_credentials, as: :json
    
    assert_response :unauthorized
  end

  test "should return JSON format for login" do
    post "/api/v1/login", params: @valid_credentials, as: :json
    
    assert_response :success
    assert_equal "application/json; charset=utf-8", response.content_type
  end

  # Logout Tests
  test "should logout with valid JWT token" do
    # First login to get a valid session
    post "/api/v1/login", params: @valid_credentials, as: :json
    assert_response :success
    
    # Extract token from response (this would be in a real JWT implementation)
    # For now, we'll use the authentication token from the user
    token = @user.authentication_token
    
    delete "/api/v1/logout", 
           headers: { "Authorization" => "Bearer #{token}" }
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert_equal 200, json_response["status"]
    assert_equal "Logged out successfully.", json_response["message"]
  end

  test "should reject logout without token" do
    delete "/api/v1/logout"
    
    assert_response :unauthorized
  end

  test "should reject logout with invalid token" do
    delete "/api/v1/logout", 
           headers: { "Authorization" => "Bearer invalid_token" }
    
    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    
    assert_equal 401, json_response["status"]
    assert_equal "Invalid token.", json_response["message"]
  end

  test "should return JSON format for logout" do
    token = @user.authentication_token
    
    delete "/api/v1/logout", 
           headers: { "Authorization" => "Bearer #{token}" }
    
    assert_response :success
    assert_equal "application/json; charset=utf-8", response.content_type
  end

  # Content Type Tests
  test "should accept JSON content type for login" do
    post "/api/v1/login", 
         params: @valid_credentials, 
         headers: { "Content-Type" => "application/json" }
    
    assert_response :success
  end

  test "should handle malformed JSON for login" do
    post "/api/v1/login", 
         params: "invalid json", 
         headers: { "Content-Type" => "application/json" }
    
    # Should handle gracefully
    assert_response :bad_request
  end

  # Security Tests
  test "should not expose sensitive user data in login response" do
    post "/api/v1/login", params: @valid_credentials, as: :json
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    # Should not include encrypted_password or authentication_token
    assert_nil json_response["data"]["encrypted_password"]
    assert_nil json_response["data"]["authentication_token"]
  end

  test "should handle multiple login attempts" do
    # First login
    post "/api/v1/login", params: @valid_credentials, as: :json
    assert_response :success
    
    # Second login should also work
    post "/api/v1/login", params: @valid_credentials, as: :json
    assert_response :success
  end

  # Edge Cases
  test "should handle very long email" do
    long_email_credentials = {
      user: {
        email: "a" * 300 + "@example.com",
        password: "password123"
      }
    }
    
    post "/api/v1/login", params: long_email_credentials, as: :json
    
    assert_response :unauthorized
  end

  test "should handle very long password" do
    long_password_credentials = {
      user: {
        email: @user.email,
        password: "a" * 1000
      }
    }
    
    post "/api/v1/login", params: long_password_credentials, as: :json
    
    assert_response :unauthorized
  end

  test "should handle special characters in credentials" do
    special_credentials = {
      user: {
        email: "test+special@example.com",
        password: "pass@word#123"
      }
    }
    
    post "/api/v1/login", params: special_credentials, as: :json
    
    # Should handle gracefully (likely unauthorized for non-existent user)
    assert_response :unauthorized
  end
end
