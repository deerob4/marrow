import TokenStore from "../thunks/TokenStore";
import { Middleware, MiddlewareAPI, Dispatch } from "redux";
import { debounce } from "lodash";
import ActionType from "../constants";
import { Action, AppState, EditorConnect, Image, Audio } from "../types";
import { Socket, Channel } from "phoenix";
import {
  connectToEditor,
  recompile,
  editGameSource
} from "../actions/EditorActions";
import { socketConnected, socketDropped } from "../actions/SocketActions";
import { push } from "connected-react-router";
import {
  uploadImage,
  uploadAudio,
} from "../actions/AssetActions";
import { toggleIsPublic } from "../actions/GameActions";

type Store = MiddlewareAPI<Next, AppState>;
type Next = Dispatch<Action>;

/**
 * Ensures that the authentication token is always stored and
 * removed when auth actions are dispatched.
 */
const authMiddleware: Middleware = (store: Store) => (next: Next) => (
  action: Action
) => {
  switch (action.type) {
    case ActionType.LOGIN_SUCCESS:
      const token = action.payload.token;
      TokenStore.set(token);
      break;

    case ActionType.LOGIN_FAILURE:
    case ActionType.LOGOUT:
      TokenStore.delete();
      break;
  }

  return next(action);
};

let socket: Socket;
let editorChannel: Channel;

const socketMiddleware: Middleware = (store: Store) => (next: Next) => (
  action: Action
) => {
  const { dispatch, getState } = store;

  switch (action.type) {
    case ActionType.LOGIN_SUCCESS:
      socket = new Socket("/socket");
      socket.connect();
      socket.onError(() => dispatch(socketDropped()));
      socket.onOpen(() => dispatch(socketConnected()));
      break;

    case ActionType.LOGOUT:
      socket.disconnect();
      break;

    case ActionType.EDITOR_CONNECT_REQUEST:
      const editorId = action.payload;
      editorChannel = socket.channel(`editor:${editorId}`);
      editorChannelActions(store);
      break;

    case ActionType.EDITOR_LEAVE:
      editorChannel.leave();
      break;

    case ActionType.EDIT_GAME_SOURCE:
      if (action.payload.broadcast) {
        editorChannel.push("edit_source", {
          source: action.payload.newSource
        });
      }
      break;

    case ActionType.TOGGLE_GAME_VISIBILITY_REQUEST:
      editorChannel
        .push("toggle_public", {})
        .receive("ok", ({ isPublic }) => {
          const gameId = getState().editingGame.metadataId;
          dispatch(toggleIsPublic.result(isPublic, gameId));
        });
      break;

    case ActionType.RECOMPILE_REQUEST:
      editorChannel
        .push("recompile", {})
        .receive("ok", ({ game }) => {
          dispatch(recompile.success(game));
        })
        .receive("error", ({ reason }) => dispatch(recompile.failure(reason)));
      break;
  }

  return next(action);
};

function editorChannelActions({ dispatch, getState }: Store) {
  editorChannel.on("connected", (r: { data: EditorConnect }) => {
    dispatch(push(`/games/${r.data.editingGame.metadataId}`));
    dispatch(connectToEditor.success(r.data));
  });

  editorChannel.on("image_uploaded", (image: Image) => {
    dispatch(uploadImage.success(image));
  });

  editorChannel.on("audio_uploaded", (audio: Audio) => {
    dispatch(uploadAudio.success(audio));
  });

  editorChannel.on("edit_source", ({ newSource }: { newSource: string }) => {
    const id = getState().editingGame.metadataId;
    dispatch(editGameSource(id, newSource, false));
  });

  editorChannel
    .join()
    .receive("error", reason => dispatch(connectToEditor.failure(reason)));
}

export { authMiddleware, socketMiddleware };
