require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should get index when user is authenticated" do
    get root_url
    assert_response :success
    assert_select "h2", "Buscar Clima por CEP"
    assert_select ".user-info .badge", @user.email
  end

  test "should redirect to login when user is not authenticated" do
    sign_out @user
    get root_url
    assert_redirected_to new_user_session_path
  end

  test "should display user's recent weather searches" do
    # Criar alguns weathers para o usuário
    weather1 = Weather.create!(
      zip: "01310100",
      temperature: 25.0,
      temp_min: 20.0,
      temp_max: 30.0,
      description: "céu limpo",
      user: @user,
    )

    weather2 = Weather.create!(
      zip: "04567890",
      temperature: 18.0,
      temp_min: 15.0,
      temp_max: 22.0,
      description: "nublado",
      user: @user,
    )

    get root_url
    assert_response :success

    # Verificar se os weathers aparecem na página
    assert_select ".weather-info h6", "CEP: 01310100"
    assert_select ".weather-info h6", "CEP: 04567890"
  end

  test "should show message when user has no weather searches" do
    # Garantir que o usuário não tem weathers
    Weather.where(user: @user).destroy_all

    get root_url
    assert_response :success
    assert_select ".alert-info", "Você ainda não fez nenhuma busca"
  end

  test "should display logout button" do
    get root_url
    assert_response :success
    assert_select "a[href='#{destroy_user_session_path}']", "Sair"
  end
end
