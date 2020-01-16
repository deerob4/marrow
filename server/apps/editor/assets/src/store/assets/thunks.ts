import { Dispatch } from "redux";
import api from "../../api";
import * as uuid from "uuid";
import { AppState } from "..";
import { authToken, headerConfig } from "../helpers";
import { AssetActionType, UploadingAssets } from "./types";
import {
  uploadImage,
  deleteImage as deleteImageAction,
  renameImage as renameImageAction
} from "./actions";

export function uploadImages(files: FileList) {
  return (dispatch: Dispatch, getState: () => AppState) => {
    const formData = new FormData();
    const token = authToken(getState);
    const gameId = getState().games.currentGame;

    const assetIds: UploadingAssets = {};

    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      const id = uuid.v4();

      assetIds[id] = file;
      formData.append(`files[${i}]`, file);
      formData.append(`fileIds[${i}]`, id);
    }

    dispatch(uploadImage.request(assetIds));

    formData.append("gameId", gameId);

    api.post("/assets", formData, headerConfig(token));
  };
}

export function uploadAudio(files: FileList) {
  return (dispatch: Dispatch, getState: () => AppState) => {
    const channel = getState().channels.editorChannel!;
    console.log(files);
  };
}

export function deleteImage(id: string) {
  return (dispatch: Dispatch, getState: () => AppState) => {
    const token = authToken(getState);

    dispatch(deleteImageAction.request(id));

    api
      .delete(`/assets/${id}`, headerConfig(token))
      .then(() => dispatch(deleteImageAction.success(id)))
      .catch(() => dispatch(deleteImageAction.failure(id)));
  };
}

export function renameImage(id: number, newName: string) {
  return (dispatch: Dispatch, getState: () => AppState) => {
    const token = authToken(getState);

    dispatch(renameImageAction.request({ id, newName }));

    api
      .put(`/assets/${id}`, { newName, type: "image" }, headerConfig(token))
      .then(() => dispatch(renameImageAction.success()))
      .catch(() => dispatch(renameImageAction.failure("Failure")));
  };
}
