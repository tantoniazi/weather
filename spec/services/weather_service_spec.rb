require "rails_helper"

RSpec.describe WeatherService, type: :service do
  let(:zip) { "12345" }
  let(:user) { create(:user) }
  let(:service) { described_class.new(zip, user) }

  describe "#forecast" do
    context "quando a API retorna sucesso" do
      let(:api_response) do
        {
          "main" => { "temp" => 25.0, "temp_min" => 22.0, "temp_max" => 28.0 },
          "weather" => [{ "description" => "céu limpo" }],
        }
      end

      before do
        stub_request(:get, %r{api.openweathermap.org/data/2.5/weather})
          .to_return(status: 200, body: api_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "retorna os dados da API" do
        result = service.forecast

        expect(result[:temperature]).to eq(25.0)
        expect(result[:description]).to eq("céu limpo")
        expect(result[:from_database]).to eq(false)
      end

      it "salva os dados no banco" do
        expect { service.forecast }.to change { Weather.count }.by(1)
        weather = Weather.last
        expect(weather.zip).to eq(zip)
        expect(weather.user_id).to eq(user.id)
        expect(weather.temperature).to eq(25.0)
        expect(weather.description).to eq("céu limpo")
      end
    end

    context "quando a API retorna vazio" do
      before do
        stub_request(:get, %r{api.openweathermap.org/data/2.5/weather})
          .to_return(status: 200, body: {}.to_json, headers: { "Content-Type" => "application/json" })

        create(:weather, zip: zip, temperature: 20.0, description: "fallback", user: user)
      end

      it "usa o dado do banco" do
        result = service.forecast
        expect(result[:temperature]).to eq(20.0)
        expect(result[:from_database]).to eq(true)
      end
    end

    context "quando a API e banco falham" do
      before do
        stub_request(:get, %r{api.openweathermap.org/data/2.5/weather})
          .to_return(status: 500, body: "")
      end

      it "retorna erro" do
        result = service.forecast
        expect(result).to eq({ error: "Unable to fetch weather data" })
      end
    end

    context "quando já existe cache" do
      it "não chama a API novamente" do
        Rails.cache.write("weather/#{zip}", { temperature: 99, from_cache: true })

        result = service.forecast
        expect(result[:temperature]).to eq(99)
        expect(result[:from_cache]).to eq(true)
      end
    end

    context "quando usuário é nil" do
      let(:service) { described_class.new(zip, nil) }

      it "salva weather sem user_id" do
        stub_request(:get, %r{api.openweathermap.org/data/2.5/weather})
          .to_return(status: 200, body: api_response.to_json, headers: { "Content-Type" => "application/json" })

        expect { service.forecast }.to change { Weather.count }.by(1)
        weather = Weather.last
        expect(weather.user_id).to be_nil
      end
    end

    context "quando CEP é inválido" do
      let(:zip) { "123" }

      it "retorna erro para CEP inválido" do
        result = service.forecast
        expect(result).to have_key(:error)
      end
    end
  end

  describe "#cached?" do
    it "retorna true quando existe cache" do
      Rails.cache.write("weather/#{zip}", { temperature: 25 })
      expect(service.cached?).to be true
    end

    it "retorna false quando não existe cache" do
      expect(service.cached?).to be false
    end
  end
end
