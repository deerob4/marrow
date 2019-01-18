import { combineReducers } from "redux";
import indexById from "../utils/indexById";
import { prop, assoc, dissoc, assocPath, append, filter } from "ramda";
import { ById, Action, Asset } from "../types";

import ActionType from "../constants";
import notEquals from "../utils/notEqual";

function byId(state: ById<Asset<"audio">> = {}, action: Action) {
  switch (action.type) {
    case ActionType.EDITOR_CONNECT_SUCCESS:
      return indexById(action.payload.audio);

    case ActionType.UPLOAD_AUDIO_SUCCESS:
      return assoc(action.payload.id, action.payload, state);

    case ActionType.DELETE_AUDIO_SUCCESS:
      return dissoc(action.payload, state);

    case ActionType.RENAME_AUDIO_SUCCESS:
      const { id, name } = action.payload;
      return assocPath([id, "name"], name, state);

    default:
      return state;
  }
}

function allIds(state: number[] = [], action: Action) {
  switch (action.type) {
    case ActionType.EDITOR_CONNECT_SUCCESS:
      return action.payload.audio.map(prop("id"));

    case ActionType.UPLOAD_AUDIO_SUCCESS:
      return append(action.payload.id, state);

    case ActionType.DELETE_AUDIO_SUCCESS:
      return filter(notEquals(action.payload), state);

    default:
      return state;
  }
}

export default combineReducers({ byId, allIds });
