import api from "../../api";
import { push } from "connected-react-router";

import { authToken, headerConfig } from "../helpers";
import {
  loadGame as loadGameAction,
  deleteGame as deleteGameAction,
  newGame as newGameAction,
  recompileGame as recompileGameAction,
  editGameSource as editGameSourceAction,
  toggleIsPublic as toggleIsPublicAction
} from "./actions";

import { updateBoardStructure } from "../board/actions";

import { AppState } from "../index";
import { Dispatch } from "redux";
import { IRecompileResponse } from "./types";

export function newGame() {
  return (dispatch: Dispatch, getState: () => AppState) => {
    const token = authToken(getState);

    dispatch(newGameAction.request());

    api
      .post("/game", {}, headerConfig(token))
      .then(r => {
        dispatch(newGameAction.success(r.data.data));
        const newGameId = r.data.data.id;
        // @ts-ignore
        dispatch(loadGame(newGameId));
      })
      .catch(e => console.log(e.response));
  };
}

export function deleteGame(id: string) {
  return (dispatch: Dispatch, getState: () => AppState) => {
    const token = authToken(getState);
    dispatch(deleteGameAction.request(id));
    api
      .delete(`/game/${id}`, headerConfig(token))
      .then(() => dispatch(deleteGameAction.success(id)))
      .catch(e => dispatch(deleteGameAction.failure(e)));
  };
}

export function loadGame(id: string) {
  return (dispatch: Dispatch) => {
    dispatch(loadGameAction(id));
    dispatch(push(`/games/${id}`));
  };
}

// export function recompileGame() {
//   return (dispatch: Dispatch, getState: () => AppState) => {
//     dispatch(recompileGameAction.request());

//     const channel = getState().channels.editorChannel!;

//     channel
//       .push("recompile", {})
//       .receive("ok", (data: IRecompileResponse) => {
//         dispatch(updateBoardStructure(data.board));
//         dispatch(recompileGameAction.success(data));
//       })
//       .receive("error", ({ reason }) =>
//         dispatch(recompileGameAction.failure(reason))
//       );
//   };
// }

export function goToGameIndex() {
  return (dispatch: Dispatch) => {
    dispatch(push("/games"));
  };
}

export function editGameSource(gameId: string, newSource: string) {
  return (dispatch: Dispatch, getState: () => AppState) => {
    dispatch(editGameSourceAction(gameId, newSource));

    const channel = getState().channels.editorChannel!;
    channel.push("update_source", { newSource });
  };
}

export function toggleIsPublic() {
  return (dispatch: Dispatch, getState: () => AppState) => {
    console.log(getState())
    const channel = getState().channels.editorChannel!;
    
    channel
    .push("toggle_is_public", {})
    .receive("ok", ({ isPublic }) =>
    dispatch(toggleIsPublicAction(isPublic))
      );
  };
}
