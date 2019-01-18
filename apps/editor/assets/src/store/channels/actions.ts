import { action, createAsyncAction } from "typesafe-actions";
import { ChannelActionType, IEditorConnect } from "./types";
import { Channel, Socket } from "phoenix";
import { EditorConnect } from "../../types";

export const connectToSocket = (socket: Socket) =>
  action(ChannelActionType.CONNECT_TO_SOCKET, socket);

export const connectToEditor = (channel: Channel, gameData: EditorConnect) =>
  action(ChannelActionType.CONNECT_TO_EDITOR, { channel, gameData });

export const leaveEditor = () => action(ChannelActionType.LEAVE_EDITOR);

export const createEditorChannel = (channel: Channel) =>
  action(ChannelActionType.CREATE_EDITOR_CHANNEL, channel);
