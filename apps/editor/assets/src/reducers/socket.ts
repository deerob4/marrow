import ActionTypes from "../constants";
import { Action, SocketState } from "../types";
import { combineReducers } from "redux";

function editorConnected(state = false, action: Action) {
  switch (action.type) {
    case ActionTypes.EDITOR_CONNECT_SUCCESS:
      return true;

    case ActionTypes.EDITOR_LEAVE:
    case ActionTypes.EDITOR_CONNECTION_DROPPED:
      return false;

    default:
      return state;
  }
}

function socketConnected(state = false, action: Action) {
  switch (action.type) {
    case ActionTypes.SOCKET_CONNECTED:
      return true;

    case ActionTypes.LOGOUT:
    case ActionTypes.SOCKET_CONNECTION_DROPPED:
      return false;

    default:
      return state;
  }
}

export default combineReducers<SocketState, Action>({
  editorConnected,
  socketConnected
});
