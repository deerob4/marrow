import { Dispatch } from "redux";
import api, { headerConfig } from "../api";
import { v4 as uuidv4 } from 'uuid';
import { UploadingAssets, AppState, RenameAsset } from "../types";
import {
  uploadImage,
  renameImage as renameImageAction,
  deleteImage as deleteImageAction
} from "../actions/AssetActions";

export function uploadImages(files: FileList) {
  return (dispatch: Dispatch, getState: () => AppState) => {
    const formData = new FormData();
    const token = getState().auth.token;
    const gameId = getState().editingGame.metadataId;

    const assetIds: UploadingAssets = {};

    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      const id = uuidv4();

      assetIds[id] = file;
      formData.append(`files[${i}]`, file);
      formData.append(`fileIds[${i}]`, id);
      formData.append("type", "image");
    }

    dispatch(uploadImage.request(assetIds));

    formData.append("gameId", gameId.toString());

    api.post("/assets", formData, headerConfig(token));
  };
}

export function renameImage(imageId: number, newName: string) {
  return (dispatch: Dispatch, getState: () => AppState) => {
    const asset: RenameAsset<"image"> = {
      id: imageId,
      name: newName,
      type: "image"
    };

    dispatch(renameImageAction.request(asset));

    const token = getState().auth.token;
    api
      .put(`/assets/${imageId}`, asset, headerConfig(token))
      .then(() => dispatch(renameImageAction.success(asset)))
      .catch(() => dispatch(renameImageAction.failure("Error")));
  };
}

export function deleteImage(imageId: number) {
  return (dispatch: Dispatch, getState: () => AppState) => {
    const token = getState().auth.token;
    
    dispatch(deleteImageAction.request(imageId));

    api
      .delete(`/assets/${imageId}?type=image`, headerConfig(token))
      .then(() => dispatch(deleteImageAction.success(imageId)))
      .catch(() => dispatch(deleteImageAction.failure(imageId)));
  };
}
