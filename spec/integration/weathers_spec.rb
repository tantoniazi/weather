require "swagger_helper"

RSpec.describe "api/v1/weathers", type: :request do
  path "/api/v1/weathers/{zip}" do
    parameter name: "zip", in: :path, type: :string, description: "CEP brasileiro (8 dígitos)"

    get("Buscar clima por CEP") do
      tags "Weather"
      description "Busca informações do clima para um CEP brasileiro específico"
      produces "application/json"
      security [Bearer: []]

      parameter name: :zip, in: :path, type: :string, description: "CEP brasileiro (8 dígitos)", example: "01310100"

      response(200, "sucesso") do
        let(:zip) { "01310100" }

        schema type: :object,
               properties: {
                 temperature: { type: :number, description: "Temperatura atual em Celsius", example: 25.0 },
                 temp_min: { type: :number, description: "Temperatura mínima em Celsius", example: 20.0 },
                 temp_max: { type: :number, description: "Temperatura máxima em Celsius", example: 30.0 },
                 description: { type: :string, description: "Descrição das condições climáticas", example: "céu limpo" },
                 from_cache: { type: :boolean, description: "Se os dados vieram do cache", example: false },
                 from_database: { type: :boolean, description: "Se os dados vieram do banco (fallback)", example: false },
               },
               required: ["temperature", "temp_min", "temp_max", "description", "from_cache", "from_database"]

        before do
          sign_in create(:user)
          WeatherService.any_instance.stubs(:forecast).returns({
            temperature: 25.0,
            temp_min: 20.0,
            temp_max: 30.0,
            description: "céu limpo",
            from_cache: false,
            from_database: false,
          })
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["temperature"]).to eq(25.0)
          expect(data["description"]).to eq("céu limpo")
        end
      end

      response(200, "erro - CEP inválido") do
        let(:zip) { "123" }

        schema type: :object,
               properties: {
                 error: { type: :string, description: "Mensagem de erro", example: "CEP deve ter 8 dígitos" },
               },
               required: ["error"]

        before do
          sign_in create(:user)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("CEP deve ter 8 dígitos")
        end
      end

      response(200, "erro - API indisponível") do
        let(:zip) { "01310100" }

        schema type: :object,
               properties: {
                 error: { type: :string, description: "Mensagem de erro", example: "Unable to fetch weather data" },
               },
               required: ["error"]

        before do
          sign_in create(:user)
          WeatherService.any_instance.stubs(:forecast).returns({ error: "Unable to fetch weather data" })
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Unable to fetch weather data")
        end
      end

      response(302, "não autorizado - redirecionamento para login") do
        let(:zip) { "01310100" }

        run_test! do |response|
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end
  end
end
