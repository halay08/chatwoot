class Api::V1::Accounts::Conversations::ParseUrlsController < Api::V1::Accounts::Conversations::BaseController
  def create
    url_data = {}
    render json: url_data
  end

  private

  def model
    @model ||= @conversation
  end

  def permitted_params
    params.permit(:conversation_id, :response_url)
  end
end
