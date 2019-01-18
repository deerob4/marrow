import { Reducer } from "redux";
import { GameActionType, GameState, CompileStatus } from "./types";
import { AuthActionType } from "../auth/types";
import { ActionType } from "typesafe-actions";
import * as actions from "./actions";
import * as authActions from "../auth/actions";
import * as channelActions from "../channels/actions";
import produce from "immer";
import { ChannelActionType } from "../channels/types";

type Action =
  | ActionType<typeof actions>
  | ActionType<typeof authActions>
  | ActionType<typeof channelActions>;

const initialState: GameState = {
  games: {},
  currentGame: "",
  isSaving: false,
  compileStatus: { type: "ok" }
};

const compileStatus = (
  status: CompileStatus = { type: "ok" },
  action: Action
): CompileStatus => {
  switch (action.type) {
    case GameActionType.RECOMPILE_GAME_REQUEST:
      return { type: "compiling" };

    case GameActionType.RECOMPILE_GAME_FAILURE:
      return { type: "error", error: action.payload };

    case GameActionType.RECOMPILE_GAME_SUCCESS:
      return { type: "ok" };

    default:
      return status;
  }
};

const reducer = produce<GameState>((draft: GameState, action: Action) => {
  switch (action.type) {
    case GameActionType.NEW_GAME_SUCCESS:
      draft.games[action.payload.id] = action.payload;
      break;

    case GameActionType.DELETE_GAME_SUCCESS:
      delete draft.games[action.payload];
      break;

    case GameActionType.LOAD_GAME:
      draft.currentGame = action.payload;
      break;

    case AuthActionType.LOGIN_SUCCESS:
    case AuthActionType.SIGNUP_SUCCESS:
    case AuthActionType.FETCH_ACCOUNT_DETAILS_SUCCESS:
      draft.currentGame = action.payload.currentGame;
      draft.games = action.payload.games.reduce(
        (games, game) => ({ ...games, [game.id]: game }),
        draft.games
      );
      break;

    case GameActionType.EDIT_GAME_SOURCE:
      var game = draft.games[action.payload.gameId];
      game.title = extractTitle(action.payload.newSource) || game.title;
      game.source = action.payload.newSource;
      break;

    case ChannelActionType.CONNECT_TO_EDITOR:
      var gameData = action.payload.gameData;
      var game = draft.games[gameData.gameId];

      game.source = gameData.source;
      game.headerImageUrl = gameData.headerImageUrl;
      game.isPublic = gameData.isPublic;

      let error = action.payload.gameData.error;

      if (error) {
        draft.compileStatus = { type: "error", error };
      }

      break;

    case GameActionType.RECOMPILE_GAME_REQUEST:
      draft.isSaving = true;
      draft.compileStatus = { type: "compiling" };
      break;

    case GameActionType.RECOMPILE_GAME_SUCCESS:
      draft.isSaving = false;
      draft.compileStatus = { type: "ok" };
      break;

    case GameActionType.RECOMPILE_GAME_FAILURE:
      draft.isSaving = false;
      draft.compileStatus = { type: "error", error: action.payload };
      break;

    case GameActionType.TOGGLE_IS_PUBLIC:
      draft.games[draft.currentGame].isPublic = action.payload;
      break;

    case AuthActionType.SIGNOUT:
      draft = initialState;
      break;
  }
}, initialState);

function extractTitle(source: string) {
  const titleRegex = /\(defgame "(.*)"/gm;
  const matches = titleRegex.exec(source);

  if (matches) return matches[1];
}

function dissoc(key: any, obj: any) {
  const copy = Object.assign({}, obj);
  delete copy[key];
  return copy;
}

export { reducer as gameReducer };
