class Facebook::SendOnFacebookService < Base::SendOnChannelService
  private

  def channel_class
    Channel::FacebookPage
  end

  def perform_reply
    if message.template?
      send_message_to_facebook fb_template_message_params
    else
      send_message_to_facebook fb_text_message_params if message.content.present?
      send_message_to_facebook fb_attachment_message_params if message.attachments.present?
    end
  rescue Facebook::Messenger::FacebookError => e
    Sentry.capture_exception(e)
    # TODO : handle specific errors or else page will get disconnected
    # channel.authorization_error!
  end

  def send_message_to_facebook(delivery_params)
    result = Facebook::Messenger::Bot.deliver(delivery_params, page_id: channel.page_id)
    message.update!(source_id: JSON.parse(result)['message_id'])
  end

  def fb_text_message_params
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: { text: message.content }
    }
  end

  def fb_attachment_message_params
    attachment = message.attachments.first
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: attachment_type(attachment),
          payload: {
            url: attachment.file_url
          }
        }
      }
    }
  end

  def prepare_msg_elements(items)
    items.map do |item|
      {
        title: item['title'],
        image_url: item['media_url'],
        subtitle: item['description'],
        buttons: [
          { type: 'web_url', url: 'https://propertyscout.co.th', title: 'Shortlist' },
          { type: 'web_url', url: 'https://propertyscout.co.th', title: 'Remove' }
        ]
      }
    end
  end

  def fb_template_message_params
    message_items = message.content_attributes.try(:[], 'items')
    return {} if message_items.blank?

    fb_msg_elements = prepare_msg_elements(message_items)
    {
      recipient: { id: contact.get_source_id(inbox.id) },
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'generic',
            elements: fb_msg_elements
          }
        }
      }
    }
  end

  def attachment_type(attachment)
    return attachment.file_type if %w[image audio video file].include? attachment.file_type

    'file'
  end

  def fb_message_params
    if message.attachments.blank?
      fb_text_message_params
    else
      fb_attachment_message_params
    end
  end

  def sent_first_outgoing_message_after_24_hours?
    # we can send max 1 message after 24 hour window
    conversation.messages.outgoing.where('id > ?', last_incoming_message.id).count == 1
  end

  def last_incoming_message
    conversation.messages.incoming.last
  end
end
