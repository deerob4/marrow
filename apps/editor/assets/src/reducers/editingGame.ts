import { combineReducers } from "redux";
import { Action, CompileStatus as CS, EditingGame } from "../types";
import ActionType from "../constants";

function metadataId(state = 0, action: Action) {
  switch (action.type) {
    case ActionType.EDITOR_CONNECT_SUCCESS:
      return action.payload.editingGame.metadataId;

    case ActionType.SET_EDITING_GAME_ID:
      return action.payload;

    case ActionType.EDITOR_LEAVE:
      return 0;

    default:
      return state;
  }
}

function source(state = "", action: Action): string {
  switch (action.type) {
    case ActionType.EDITOR_CONNECT_SUCCESS:
      return action.payload.editingGame.source;

    case ActionType.EDITOR_LEAVE:
      return "";

    case ActionType.EDIT_GAME_SOURCE:
      return action.payload.newSource;

    default:
      return state;
  }
}

function compileStatus(state: CS = { type: "ok" }, action: Action): CS {
  switch (action.type) {
    case ActionType.RECOMPILE_REQUEST:
      return { type: "compiling" };

    case ActionType.RECOMPILE_SUCCESS:
      return { type: "ok" };

    case ActionType.RECOMPILE_FAILURE:
      return { type: "error", error: action.payload };

    case ActionType.EDITOR_CONNECT_SUCCESS:
      return action.payload.editingGame.compileStatus;

    default:
      return state;
  }
}

export default combineReducers<EditingGame, Action>({
  metadataId,
  source,
  compileStatus
});
