import Vue from 'vue';
import * as types from '../mutation-types';
import ConversationAPI from '../../api/conversations';

const state = {
  reponseUrlData: {},
  uiFlags: {
    isFetching: false,
    isUpdating: false,
    isError: false,
  },
};

export const getters = {
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getResponseUrlData($state) {
    return $state.reponseUrlData;
  },
};

export const actions = {
  update: async ({ commit }, { conversationId, labels }) => {
    commit(types.default.SET_CONVERSATION_LABELS_UI_FLAG, {
      isUpdating: true,
    });
    try {
      const response = await ConversationAPI.updateLabels(
        conversationId,
        labels
      );
      commit(types.default.SET_CONVERSATION_LABELS, {
        id: conversationId,
        data: response.data.payload,
      });
      commit(types.default.SET_CONVERSATION_LABELS_UI_FLAG, {
        isUpdating: false,
        isError: false,
      });
    } catch (error) {
      commit(types.default.SET_CONVERSATION_LABELS_UI_FLAG, {
        isUpdating: false,
        isError: true,
      });
    }
  },
  parseResponseUrl: async ({ commit }, { conversationId, responseUrl }) => {
    commit(types.default.SET_RESPONSE_URL_DATA_UI_FLAG, {
      isUpdating: true,
    });
    try {
      const response = await ConversationAPI.parseResponseUrl(
        conversationId,
        responseUrl
      );
      commit(types.default.SET_RESPONSE_URL_DATA, {
        id: conversationId,
        data: response.data,
      });
      commit(types.default.SET_RESPONSE_URL_DATA_UI_FLAG, {
        isUpdating: false,
        isError: false,
      });
    } catch (error) {
      commit(types.default.SET_RESPONSE_URL_DATA_UI_FLAG, {
        isUpdating: false,
        isError: true,
      });
    }
  },
};

export const mutations = {
  [types.default.SET_RESPONSE_URL_DATA_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.default.SET_RESPONSE_URL_DATA]: ($state, { id, data }) => {
    Vue.set($state.reponseUrlData, id, data);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
