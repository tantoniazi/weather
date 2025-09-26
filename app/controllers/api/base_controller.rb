class Api::BaseController < ActionController::API
  before_action :authenticate_with_token!

  private

  def authenticate_with_token!
    token = request.headers['Authorization']&.split(' ')&.last
    @current_user = User.find_by(authentication_token: token)
    render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
  end
end