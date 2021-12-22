class Line::SendOnLineService < Base::SendOnChannelService
  private

  LINE_TITLE_MAX_LENGTH = 40

  def channel_class
    Channel::Line
  end

  def perform_reply
    message_data = if message.template?
                     template_message_params
                   else
                     text_message_params
                   end
    channel.client.push_message(
      message.conversation.contact_inbox.source_id,
      [message_data]
    )
  end

  def text_message_params
    { type: 'text', text: message.content }
  end

  def prepare_msg_columns(items)
    items.map do |item|
      actions = item['actions'].map do |action|
        { type: 'uri', label: action['text'], uri: action['uri'] }
      end
      {
        'thumbnailImageUrl': item['media_url'],
        'imageBackgroundColor': '#FFFFFF',
        'title': item['title']&.truncate(LINE_TITLE_MAX_LENGTH),
        'text': item['description'],
        'actions': actions
      }
    end
  end

  def template_message_params
    message_items = message.content_attributes.try(:[], 'items')
    return {} if message_items.blank?

    msg_columns = prepare_msg_columns(message_items)
    {
      'type': 'template',
      'altText': 'this is a carousel template',
      'template': {
        'type': 'carousel',
        'columns': msg_columns,
        'imageAspectRatio': 'rectangle',
        'imageSize': 'cover'
      }
    }
  end
end
