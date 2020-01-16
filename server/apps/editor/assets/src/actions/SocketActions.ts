import ActionTypes from "../constants";
import { action } from "typesafe-actions";

export const socketConnected = () => action(ActionTypes.SOCKET_CONNECTED);

export const socketDropped = () =>
  action(ActionTypes.SOCKET_CONNECTION_DROPPED);

export const editorDropped = () =>
  action(ActionTypes.EDITOR_CONNECTION_DROPPED);
