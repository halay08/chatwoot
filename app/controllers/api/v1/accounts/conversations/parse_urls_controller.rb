class Api::V1::Accounts::Conversations::ParseUrlsController < Api::V1::Accounts::Conversations::BaseController
  def create
    url_data = CrawlMessageData.new(permitted_params[:response_url]).perform
    render json: url_data
  end

  private

  def model
    @model ||= @conversation
  end

  def permitted_params
    params.permit(:response_url)
  end
end
