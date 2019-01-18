import { Dispatch } from "redux";
import { AppState } from "../types";
import api, { headerConfig } from "../api";
import { newGame as newGameAction, deleteGame as deleteGameAction } from "../actions/GameActions";

export function newGame() {
  return (dispatch: Dispatch, getState: () => AppState) => {
    const token = getState().auth.token;

    api
      .post("/games", {}, headerConfig(token))
      .then(r => dispatch(newGameAction.success(r.data.data)))
      .catch(e => dispatch(newGameAction.failure("error")));
  };
}

export function deleteGame(id: number) {
  return (dispatch: Dispatch, getState: () => AppState) => {
    dispatch(deleteGameAction.request(id));

    const token = getState().auth.token;

    api
      .delete(`/games/${id}`, headerConfig(token))
      .then(() => dispatch(deleteGameAction.success(id)))
      .catch(() => deleteGameAction.failure("error"));
  };
}
