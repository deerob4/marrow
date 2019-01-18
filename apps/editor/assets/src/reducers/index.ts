import { combineReducers } from "redux";
import { connectRouter } from "connected-react-router";
import { History } from "history";
import { AppState, Action } from "../types";
import ActionType from "../constants";

import imageReducer, { deletingImages } from "../reducers/images";
import audioReducer from "../reducers/audio";
import authReducer from "../reducers/auth";
import socketReducer from "../reducers/socket";
import boardReducer from "../reducers/board";
import userReducer from "../reducers/user";
import editingGameReducer from "../reducers/editingGame";
import gameMetadataReducer from "../reducers/gameMetadata";
import cardReducer from "../reducers/cards";
import traitReducer from "../reducers/traits";

const createAppReducer = (history: History) =>
  combineReducers<AppState>({
    // @ts-ignore
    router: connectRouter(history),
    images: imageReducer,
    audio: audioReducer,
    auth: authReducer,
    editingGame: editingGameReducer,
    gameMetadata: gameMetadataReducer,
    cards: cardReducer,
    socket: socketReducer,
    user: userReducer,
    board: boardReducer,
    traits: traitReducer,
    deletingImages
  });

export const createRootReducer = (history: History) => (
  state: AppState | undefined,
  action: Action
) => {
  // if (action.type === ActionType.LOGOUT && state) {
  //   const { router } = state;
  //   // @ts-ignore
  //   state = { router };
  // }

  return createAppReducer(history)(state, action);
};
