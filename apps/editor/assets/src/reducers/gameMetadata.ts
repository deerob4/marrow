import { combineReducers } from "redux";
import { prop, filter, dissoc, assoc, append, assocPath } from "ramda";

import {
  ById,
  Action,
  GameMetadata as GM,
  GameMetadataState as GMS
} from "../types";

import ActionType from "../constants";
import indexById from "../utils/indexById";
import notEquals from "../utils/notEqual";

function byId(state: ById<GM> = {}, action: Action): ById<GM> {
  switch (action.type) {
    case ActionType.LOGIN_SUCCESS:
      return indexById(action.payload.games);

    case ActionType.DELETE_GAME_SUCCESS:
      return dissoc(action.payload, state);

    case ActionType.NEW_GAME_SUCCESS:
      return assoc(action.payload.id, action.payload, state);

    // Make sure we keep the title in sync with the game source.
    case ActionType.EDIT_GAME_SOURCE: {
      const { gameId, newSource } = action.payload;
      const title = extractTitle(newSource);

      if (title) {
        return assocPath([gameId, "title"], title, state);
      } else {
        return state;
      }
    }

    case ActionType.TOGGLE_GAME_VISIBILITY_RESULT:
      return assocPath(
        [action.payload.gameId, "isPublic"],
        action.payload.isPublic,
        state
      );

    default:
      return state;
  }
}

function allIds(state: number[] = [], action: Action): number[] {
  switch (action.type) {
    case ActionType.LOGIN_SUCCESS:
      return action.payload.games.map(prop("id"));

    case ActionType.DELETE_GAME_SUCCESS:
      return filter(notEquals(action.payload), state);

    case ActionType.NEW_GAME_SUCCESS:
      return append(action.payload.id, state);

    default:
      return state;
  }
}

function extractTitle(source: string) {
  const titleRegex = /\(defgame "(.*)"/;
  const match = source.match(titleRegex);

  return match ? match[1] : null;
}

export default combineReducers<GMS, Action>({ byId, allIds });
