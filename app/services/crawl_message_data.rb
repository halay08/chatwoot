class CrawlMessageData
  def initialize(url)
    @url = url
    @locale, @propertypad_identifier = url_infos
  end

  def perform
    format_message_data
  rescue StandardError => e
    Rails.logger.error "Exception: get rentals data from #{url} : #{e.message}"
    []
  end

  private

  attr_reader :url, :locale, :propertypad_identifier

  DOMAIN = 'https://propertyscout.co.th'.freeze
  API_PROPERTY_PAD_ENDPOINT = 'https://cms.propertyscout.co.th/property-pads'.freeze
  API_RENTALS_LIST_ENDPOINT = 'https://cms.propertyscout.co.th/rentals'.freeze
  API_IMAGE_ENDPOINT = 'https://propertyscout.co.th/_next/image?url=https://cdn.staticflexstay.com'.freeze
  API_RENTAL_DETAIL_ENDPOINT = 'https://propertyscout.co.th/'.freeze
  VALID_URL_REGEX = %r{https://propertyscout.co.th/(\w{0,2})/{0,1}propertypad/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/{0,1}}
  LINE_TITLE_MAX_LENGTH = 40

  def url_infos
    url_match_data = VALID_URL_REGEX.match(url)
    return [] if url_match_data.blank?

    locale = (url_match_data[1].presence || 'th').downcase
    propertypad_identifier = url_match_data[2]
    [locale, propertypad_identifier]
  end

  def load_rental_ids
    propertypad_data = load_response_data("#{API_PROPERTY_PAD_ENDPOINT}?identifier=#{propertypad_identifier}")
    propertypad_data.map { |p| p['rental_ids'].map { |a| a['rental_id'] } }.flatten
  end

  def load_response_data(request_url)
    response = RestClient.get(request_url)
    return [] if response.code != 200

    JSON.parse(response.body)
  end

  def load_rentals_data
    rental_ids = load_rental_ids
    return [] if rental_ids.blank?

    params = rental_ids.inject('') { |p, id| p << "id_in=#{id}&" }
    load_response_data("#{API_RENTALS_LIST_ENDPOINT}?#{params}")
  end

  def img_url(rental)
    "#{API_IMAGE_ENDPOINT}/#{rental['cdnImages']&.first.try(:[], 'url')}&w=1024&q=75"
  end

  def detail_rental_url(rental_id)
    "#{DOMAIN}/#{locale}/#{rental_id}"
  end

  def format_currency(currency)
    ActiveSupport::NumberHelper.number_to_currency(currency, unit: '฿', precision: 0)
  end

  def rental_description(rental)
    subdistrict_key = "subdistrict_ps_#{locale}"
    province_key = "province_ps_#{locale}"
    des = ''
    des << "#{rental[subdistrict_key]}, #{rental[province_key]} \n"
    des << "#{format_currency(rental['salePrice'])}\n" if rental['salePrice'].present?
    des << "#{format_currency(rental['lowestPrice'])}/#{rental['minLeasePeriod'].split('_').last&.singularize}"
    des
  end

  def rental_title(rental)
    if rental['buildingId']
      rental['buildingId'].try(:[], "name_#{locale}")
    else
      long_title = rental["listingTitle#{locale.titleize}GenStandard"]
      long_title.size > LINE_TITLE_MAX_LENGTH ? rental["listingTitle#{locale.titleize}GenShort"] : long_title
    end
  end

  def format_message_data
    load_rentals_data.map do |rental|
      {
        rental_image: img_url(rental),
        rental_title: rental_title(rental),
        rental_desc: rental_description(rental),
        rental_url: detail_rental_url(rental['id'])
      }
    end
  end
end
