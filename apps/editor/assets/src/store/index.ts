import { combineReducers } from "redux";
import { connectRouter } from "connected-react-router";
import { History } from "history";
import { AppState } from "../types";

import imageReducer from "../reducers/images";
import audioReducer from "../reducers/audio";
import authReducer from "../reducers/auth";
import boardReducer from "../reducers/board";
import userReducer from "../reducers/user";
import editingGameReducer from "../reducers/editingGame";
import gameMetadataReducer from "../reducers/gameMetadata";
import cardReducer from "../reducers/cards";

export const createRootReducer = (history: History) =>
  combineReducers<AppState>({
    // @ts-ignore
    router: connectRouter(history),
    images: imageReducer,
    audio: audioReducer,
    auth: authReducer,
    editingGame: editingGameReducer,
    gameMetadata: gameMetadataReducer,
    cards: cardReducer,
    user: userReducer,
    board: boardReducer,
  });
