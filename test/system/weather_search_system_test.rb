require "application_system_test_case"

class WeatherSearchSystemTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "visiting the index" do
    visit root_url
    assert_selector "h2", text: "Buscar Clima por CEP"
    assert_selector "input[name='zipcode']"
    assert_selector "button[type='submit']", text: "Buscar"
  end

  test "searching for weather with valid zipcode" do
    visit root_url

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

    fill_in "zipcode", with: "01310100"
    click_button "Buscar"

    assert_selector "h4", text: "Clima para CEP: 01310100"
    assert_selector ".display-4", text: "25.0°C"
    assert_selector ".text-capitalize", text: "céu limpo"
  end

  test "searching with invalid zipcode shows error" do
    visit root_url

    fill_in "zipcode", with: "123"
    click_button "Buscar"

    assert_selector ".alert-danger", text: "CEP deve ter 8 dígitos"
  end

  test "searching with empty zipcode" do
    visit root_url

    fill_in "zipcode", with: ""
    click_button "Buscar"

    # Página deve permanecer na mesma sem mostrar dados de weather
    assert_selector "h2", text: "Buscar Clima por CEP"
  end

  test "user can see their email and logout button" do
    visit root_url

    assert_selector ".badge", text: @user.email
    assert_selector "a", text: "Sair"
  end

  test "user can logout" do
    visit root_url

    click_link "Sair"

    # Deve ser redirecionado para página de login
    assert_current_path new_user_session_path
  end

  test "user can see their weather history" do
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

    visit root_url

    assert_selector "h5", text: "Suas Buscas Recentes"
    assert_selector ".weather-info h6", text: "CEP: 01310100"
    assert_selector ".weather-info h6", text: "CEP: 04567890"
  end

  test "user sees message when no weather history exists" do
    # Garantir que o usuário não tem weathers
    Weather.where(user: @user).destroy_all

    visit root_url

    assert_selector ".alert-info", text: "Você ainda não fez nenhuma busca"
  end

  test "form validation works correctly" do
    visit root_url

    # Testar CEP com hífen
    fill_in "zipcode", with: "01310-100"

    weather_data = {
      temperature: 25.0,
      temp_min: 20.0,
      temp_max: 30.0,
      description: "céu limpo",
      from_cache: false,
      from_database: false,
    }

    WeatherService.any_instance.stubs(:forecast).returns(weather_data)

    click_button "Buscar"

    assert_selector "h4", text: "Clima para CEP: 01310100"
  end

  test "weather data display includes all fields" do
    visit root_url

    weather_data = {
      temperature: 25.0,
      temp_min: 20.0,
      temp_max: 30.0,
      description: "céu limpo",
      from_cache: false,
      from_database: false,
    }

    WeatherService.any_instance.stubs(:forecast).returns(weather_data)

    fill_in "zipcode", with: "01310100"
    click_button "Buscar"

    # Verificar se todos os campos aparecem
    assert_selector ".display-4", text: "25.0°C" # Temperatura atual
    assert_selector ".text-capitalize", text: "céu limpo" # Descrição
    assert_selector ".text-danger", text: "30.0°C" # Temp máxima
    assert_selector ".text-info", text: "20.0°C" # Temp mínima
  end

  test "database fallback indicator is shown" do
    visit root_url

    weather_data = {
      temperature: 20.0,
      temp_min: 15.0,
      temp_max: 25.0,
      description: "nublado",
      from_cache: false,
      from_database: true,
    }

    WeatherService.any_instance.stubs(:forecast).returns(weather_data)

    fill_in "zipcode", with: "01310100"
    click_button "Buscar"

    assert_selector ".alert-info", text: "Dados obtidos do banco de dados"
  end
end
