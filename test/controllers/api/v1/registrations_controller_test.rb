require "test_helper"

class Api::V1::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @valid_user_params = {
      user: {
        email: "newuser@example.com",
        password: "password123",
        password_confirmation: "password123",
        address: "New User Address",
        country: "Brasil",
        zip_code: "01310-100"
      }
    }
    
    @invalid_user_params = {
      user: {
        email: "invalid-email",
        password: "123",
        password_confirmation: "456",
        address: "",
        country: "",
        zip_code: ""
      }
    }
  end

  # Registration Tests
  test "should register new user with valid data" do
    assert_difference('User.count', 1) do
      post "/api/v1/signup", params: @valid_user_params, as: :json
    end
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    assert_equal 200, json_response["status"]["code"]
    assert_equal "Signed up successfully.", json_response["status"]["message"]
    assert_equal "newuser@example.com", json_response["data"]["email"]
  end

  test "should reject registration with invalid email" do
    invalid_email_params = @valid_user_params.deep_dup
    invalid_email_params[:user][:email] = "invalid-email"
    
    assert_no_difference('User.count') do
      post "/api/v1/signup", params: invalid_email_params, as: :json
    end
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    
    assert_equal 422, json_response["status"]["code"]
    assert_equal "User couldn't be created successfully.", json_response["status"]["message"]
    assert_includes json_response["errors"], "Email is invalid"
  end

  test "should reject registration with duplicate email" do
    # Use existing user email
    duplicate_email_params = @valid_user_params.deep_dup
    duplicate_email_params[:user][:email] = users(:api_user).email
    
    assert_no_difference('User.count') do
      post "/api/v1/signup", params: duplicate_email_params, as: :json
    end
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    
    assert_equal 422, json_response["status"]["code"]
    assert_includes json_response["errors"], "Email has already been taken"
  end

  test "should reject registration with short password" do
    short_password_params = @valid_user_params.deep_dup
    short_password_params[:user][:password] = "123"
    short_password_params[:user][:password_confirmation] = "123"
    
    assert_no_difference('User.count') do
      post "/api/v1/signup", params: short_password_params, as: :json
    end
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    
    assert_equal 422, json_response["status"]["code"]
    assert_includes json_response["errors"], "Password is too short (minimum is 6 characters)"
  end

  test "should reject registration with mismatched passwords" do
    mismatched_password_params = @valid_user_params.deep_dup
    mismatched_password_params[:user][:password] = "password123"
    mismatched_password_params[:user][:password_confirmation] = "differentpassword"
    
    assert_no_difference('User.count') do
      post "/api/v1/signup", params: mismatched_password_params, as: :json
    end
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    
    assert_equal 422, json_response["status"]["code"]
    assert_includes json_response["errors"], "Password confirmation doesn't match Password"
  end

  test "should reject registration with empty required fields" do
    empty_params = {
      user: {
        email: "",
        password: "",
        password_confirmation: ""
      }
    }
    
    assert_no_difference('User.count') do
      post "/api/v1/signup", params: empty_params, as: :json
    end
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    
    assert_equal 422, json_response["status"]["code"]
    assert_includes json_response["errors"], "Email can't be blank"
    assert_includes json_response["errors"], "Password can't be blank"
  end

  # Content Type Tests
  test "should return JSON format for registration" do
    post "/api/v1/signup", params: @valid_user_params, as: :json
    
    assert_response :success
    assert_equal "application/json; charset=utf-8", response.content_type
  end

  test "should accept JSON content type for registration" do
    post "/api/v1/signup", 
         params: @valid_user_params, 
         headers: { "Content-Type" => "application/json" }
    
    assert_response :success
  end

  # User Creation Tests
  test "should create user with authentication token" do
    post "/api/v1/signup", params: @valid_user_params, as: :json
    
    assert_response :success
    
    # Verify user was created with authentication token
    new_user = User.find_by(email: "newuser@example.com")
    assert_not_nil new_user
    assert_not_nil new_user.authentication_token
    assert new_user.authentication_token.length > 10
  end

  test "should create user with all provided attributes" do
    post "/api/v1/signup", params: @valid_user_params, as: :json
    
    assert_response :success
    
    new_user = User.find_by(email: "newuser@example.com")
    assert_equal "New User Address", new_user.address
    assert_equal "Brasil", new_user.country
    assert_equal "01310-100", new_user.zip_code
  end

  test "should create unconfirmed user by default" do
    post "/api/v1/signup", params: @valid_user_params, as: :json
    
    assert_response :success
    
    new_user = User.find_by(email: "newuser@example.com")
    assert_nil new_user.confirmed_at
  end

  # Security Tests
  test "should not expose sensitive data in registration response" do
    post "/api/v1/signup", params: @valid_user_params, as: :json
    
    assert_response :success
    json_response = JSON.parse(response.body)
    
    # Should not include encrypted_password
    assert_nil json_response["data"]["encrypted_password"]
    # Should not include authentication_token in response
    assert_nil json_response["data"]["authentication_token"]
  end

  test "should handle malformed JSON for registration" do
    post "/api/v1/signup", 
         params: "invalid json", 
         headers: { "Content-Type" => "application/json" }
    
    # Should handle gracefully
    assert_response :bad_request
  end

  # Edge Cases
  test "should handle very long email" do
    long_email_params = @valid_user_params.deep_dup
    long_email_params[:user][:email] = "a" * 300 + "@example.com"
    
    assert_no_difference('User.count') do
      post "/api/v1/signup", params: long_email_params, as: :json
    end
    
    assert_response :unprocessable_entity
  end

  test "should handle very long password" do
    long_password_params = @valid_user_params.deep_dup
    long_password = "a" * 1000
    long_password_params[:user][:password] = long_password
    long_password_params[:user][:password_confirmation] = long_password
    
    # This might succeed or fail depending on password length limits
    post "/api/v1/signup", params: long_password_params, as: :json
    
    # Should handle gracefully (either success or validation error)
    assert_includes [200, 422], response.status
  end

  test "should handle special characters in email" do
    special_email_params = @valid_user_params.deep_dup
    special_email_params[:user][:email] = "test+special@example.com"
    
    post "/api/v1/signup", params: special_email_params, as: :json
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "test+special@example.com", json_response["data"]["email"]
  end

  test "should handle special characters in address" do
    special_address_params = @valid_user_params.deep_dup
    special_address_params[:user][:address] = "Rua das Flores, 123 - Apto 45B"
    
    post "/api/v1/signup", params: special_address_params, as: :json
    
    assert_response :success
    
    new_user = User.find_by(email: "newuser@example.com")
    assert_equal "Rua das Flores, 123 - Apto 45B", new_user.address
  end

  # Multiple Registration Tests
  test "should handle multiple registration attempts with same data" do
    # First registration
    post "/api/v1/signup", params: @valid_user_params, as: :json
    assert_response :success
    
    # Second registration with same email should fail
    post "/api/v1/signup", params: @valid_user_params, as: :json
    assert_response :unprocessable_entity
  end

  test "should handle concurrent registration attempts" do
    # This test simulates concurrent requests
    threads = []
    
    2.times do |i|
      params = @valid_user_params.deep_dup
      params[:user][:email] = "concurrent#{i}@example.com"
      
      threads << Thread.new do
        post "/api/v1/signup", params: params, as: :json
      end
    end
    
    threads.each(&:join)
    
    # Both should succeed with different emails
    assert_equal 2, User.where("email LIKE ?", "concurrent%@example.com").count
  end
end
