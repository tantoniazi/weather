class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    # Página inicial com busca de weather
  end
end
