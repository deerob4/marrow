import { action, createAsyncAction } from "typesafe-actions";
import { AssetActionType, UploadingAssets, IAsset } from "./types";

export const uploadImage = createAsyncAction(
  AssetActionType.UPLOAD_IMAGE_REQUEST,
  AssetActionType.UPLOAD_IMAGE_SUCCESS,
  AssetActionType.UPLOAD_IMAGE_FAILURE
)<UploadingAssets, IAsset, number>();

export const deleteImage = createAsyncAction(
  AssetActionType.DELETE_IMAGE_REQUEST,
  AssetActionType.DELETE_IMAGE_SUCCESS,
  AssetActionType.DELETE_IMAGE_FAILURE
)<string, string, string>();

export const renameImage = createAsyncAction(
  AssetActionType.RENAME_IMAGE_REQUEST,
  AssetActionType.RENAME_IMAGE_SUCCESS,
  AssetActionType.RENAME_IMAGE_FAILURE
)<{ id: number; newName: string }, void, string>();
