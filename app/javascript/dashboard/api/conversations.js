/* global axios */
import ApiClient from './ApiClient';

class ConversationApi extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  getLabels(conversationID) {
    return axios.get(`${this.url}/${conversationID}/labels`);
  }

  updateLabels(conversationID, labels) {
    return axios.post(`${this.url}/${conversationID}/labels`, { labels });
  }

  parseResponseUrl(conversationId, responseUrl) {
    return axios.post(`${this.url}/${conversationId}/parse_urls`, {
      response_url: responseUrl,
    });
  }
}

export default new ConversationApi();
