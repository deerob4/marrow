import { createAsyncAction } from "typesafe-actions";
import ActionType from "../constants";
import { UploadingAssets, Image, RenameAsset, Audio } from "../types";

/**
 * Asynchronous action to upload a new image file.
 */
export const uploadImage = createAsyncAction(
  ActionType.UPLOAD_IMAGE_REQUEST,
  ActionType.UPLOAD_IMAGE_SUCCESS,
  ActionType.UPLOAD_IMAGE_FAILURE
)<UploadingAssets, Image, number>();

/**
 * Asynchronous action to delete an image file.
 */
export const deleteImage = createAsyncAction(
  ActionType.DELETE_IMAGE_REQUEST,
  ActionType.DELETE_IMAGE_SUCCESS,
  ActionType.DELETE_IMAGE_FAILURE
)<number, number, number>();

/**
 * Asynchronous action to rename an image file.
 */
export const renameImage = createAsyncAction(
  ActionType.RENAME_IMAGE_REQUEST,
  ActionType.RENAME_IMAGE_SUCCESS,
  ActionType.RENAME_IMAGE_FAILURE
)<RenameAsset<"image">, RenameAsset<"image">, string>();

/**
 * Asynchronous action to upload a new audio file.
 */
export const uploadAudio = createAsyncAction(
  ActionType.UPLOAD_AUDIO_REQUEST,
  ActionType.UPLOAD_AUDIO_SUCCESS,
  ActionType.UPLOAD_AUDIO_FAILURE
)<UploadingAssets, Audio, number>();

/**
 * Asynchronous action to delete an audio file.
 */
export const deleteAudio = createAsyncAction(
  ActionType.DELETE_AUDIO_REQUEST,
  ActionType.DELETE_AUDIO_SUCCESS,
  ActionType.DELETE_AUDIO_FAILURE
)<number, number, number>();

/**
 * Asynchronous action to rename an audio file.
 */
export const renameAudio = createAsyncAction(
  ActionType.RENAME_AUDIO_REQUEST,
  ActionType.RENAME_AUDIO_SUCCESS,
  ActionType.RENAME_AUDIO_FAILURE
)<RenameAsset<"audio">, RenameAsset<"audio">, string>();
