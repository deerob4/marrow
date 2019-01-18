import { Socket } from "phoenix";
import { Dispatch } from "redux";
import { AppState } from "..";
import {
  connectToEditor as connectToEditorAction,
  leaveEditor as leaveEditorAction,
  connectToSocket as connectToSocketAction,
  createEditorChannel as createEditorChannelAction
} from "./actions";
import { IEditorConnect } from "./types";
import { uploadImage } from "../assets/actions";

export function connectToSocket() {
  return (dispatch: Dispatch, getState: () => AppState) => {
    const authToken = getState().auth.token;
    const socket = new Socket("/socket", { params: { authToken: authToken } });
    socket.connect();

    socket.onError(() => {
      console.log("Error!");
    });

    dispatch(connectToSocketAction(socket));
  };
}

export function connectToEditor(editorId: string) {
  return (dispatch: Dispatch, getState: () => AppState, x: number) => {
    const socket = getState().channels.socket!;
    const channel = socket.channel(`editor:${editorId}`);

    channel.on("initial_data", (gameData: IEditorConnect) => {
      console.log(gameData)
      dispatch(connectToEditorAction(channel, gameData));
    });

    channel.on("image_uploaded", ({ id, url, name }) => {
      dispatch(uploadImage.success({ id, url, name }));
    });

    channel.on("audio_uploaded", ({ id, url }) => {
      // dispatch(uploadAsset.success({ id, url, type: "audio" }));
    });

    channel.onError(reason => {
      // @ts-ignore
      // dispatch(leaveEditor());
    });

    channel.join();

    dispatch(createEditorChannelAction(channel));
  };
}

export function leaveEditor() {
  return (dispatch: Dispatch, getState: () => AppState) => {
    const channel = getState().channels.editorChannel;

    if (channel) {
      channel.leave();
      dispatch(leaveEditorAction());
    }
  };
}

