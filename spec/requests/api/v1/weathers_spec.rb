require "rails_helper"

RSpec.describe "Api::V1::Weathers", type: :request do
  let(:user) { create(:user) }
  let(:valid_zip) { "01310100" }
  let(:invalid_zip) { "123" }

  before do
    sign_in user
  end

  describe "GET /api/v1/weathers/:zip" do
    context "with valid zipcode" do
      let(:weather_data) do
        {
          temperature: 25.0,
          temp_min: 20.0,
          temp_max: 30.0,
          description: "céu limpo",
          from_cache: false,
          from_database: false,
        }
      end

      before do
        WeatherService.any_instance.stubs(:forecast).returns(weather_data)
      end

      it "returns weather data successfully" do
        get "/api/v1/weathers/#{valid_zip}"

        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("application/json; charset=utf-8")

        json_response = JSON.parse(response.body)
        expect(json_response["temperature"]).to eq(25.0)
        expect(json_response["temp_min"]).to eq(20.0)
        expect(json_response["temp_max"]).to eq(30.0)
        expect(json_response["description"]).to eq("céu limpo")
        expect(json_response["from_cache"]).to eq(false)
        expect(json_response["from_database"]).to eq(false)
      end

      it "creates a weather record in database" do
        expect {
          get "/api/v1/weathers/#{valid_zip}"
        }.to change(Weather, :count).by(1)

        weather = Weather.last
        expect(weather.zip).to eq(valid_zip)
        expect(weather.user_id).to eq(user.id)
        expect(weather.temperature).to eq(25.0)
      end

      it "returns cached data when available" do
        weather_data[:from_cache] = true
        WeatherService.any_instance.stubs(:forecast).returns(weather_data)

        get "/api/v1/weathers/#{valid_zip}"

        json_response = JSON.parse(response.body)
        expect(json_response["from_cache"]).to eq(true)
      end

      it "returns database fallback when API fails" do
        weather_data[:from_database] = true
        WeatherService.any_instance.stubs(:forecast).returns(weather_data)

        get "/api/v1/weathers/#{valid_zip}"

        json_response = JSON.parse(response.body)
        expect(json_response["from_database"]).to eq(true)
      end
    end

    context "with invalid zipcode" do
      it "returns error for short zipcode" do
        get "/api/v1/weathers/#{invalid_zip}"

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("CEP deve ter 8 dígitos")
      end

      it "returns error for empty zipcode" do
        get "/api/v1/weathers/"

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when weather service returns error" do
      before do
        WeatherService.any_instance.stubs(:forecast).returns({ error: "Unable to fetch weather data" })
      end

      it "returns error response" do
        get "/api/v1/weathers/#{valid_zip}"

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Unable to fetch weather data")
      end
    end

    context "authentication" do
      it "requires authentication" do
        sign_out user
        get "/api/v1/weathers/#{valid_zip}"

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_user_session_path)
      end

      it "works with authenticated user" do
        WeatherService.any_instance.stubs(:forecast).returns({
          temperature: 25.0,
          temp_min: 20.0,
          temp_max: 30.0,
          description: "céu limpo",
          from_cache: false,
          from_database: false,
        })

        get "/api/v1/weathers/#{valid_zip}"

        expect(response).to have_http_status(:success)
      end
    end

    context "response format" do
      before do
        WeatherService.any_instance.stubs(:forecast).returns({
          temperature: 25.0,
          temp_min: 20.0,
          temp_max: 30.0,
          description: "céu limpo",
          from_cache: false,
          from_database: false,
        })
      end

      it "returns valid JSON structure" do
        get "/api/v1/weathers/#{valid_zip}"

        expect(response).to have_http_status(:success)
        expect { JSON.parse(response.body) }.not_to raise_error

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key("temperature")
        expect(json_response).to have_key("temp_min")
        expect(json_response).to have_key("temp_max")
        expect(json_response).to have_key("description")
        expect(json_response).to have_key("from_cache")
        expect(json_response).to have_key("from_database")
      end

      it "returns proper content type" do
        get "/api/v1/weathers/#{valid_zip}"

        expect(response.content_type).to eq("application/json; charset=utf-8")
      end
    end

    context "edge cases" do
      it "handles zipcode with hyphens" do
        WeatherService.any_instance.stubs(:forecast).returns({
          temperature: 25.0,
          temp_min: 20.0,
          temp_max: 30.0,
          description: "céu limpo",
          from_cache: false,
          from_database: false,
        })

        get "/api/v1/weathers/01310-100"

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response["temperature"]).to eq(25.0)
      end

      it "handles very long zipcode" do
        get "/api/v1/weathers/123456789"

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("CEP deve ter 8 dígitos")
      end

      it "handles special characters in zipcode" do
        get "/api/v1/weathers/abc12345"

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("CEP deve ter 8 dígitos")
      end
    end

    context "performance" do
      it "responds within reasonable time" do
        WeatherService.any_instance.stubs(:forecast).returns({
          temperature: 25.0,
          temp_min: 20.0,
          temp_max: 30.0,
          description: "céu limpo",
          from_cache: false,
          from_database: false,
        })

        start_time = Time.current
        get "/api/v1/weathers/#{valid_zip}"
        end_time = Time.current

        expect(response).to have_http_status(:success)
        expect(end_time - start_time).to be < 2.seconds
      end
    end
  end
end
