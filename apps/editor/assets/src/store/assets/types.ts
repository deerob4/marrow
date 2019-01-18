export type AssetType = "image" | "audio";

export const enum AssetActionType {
  UPLOAD_IMAGE_REQUEST = "@@asset/UPLOAD_IMAGE_REQUEST",
  UPLOAD_IMAGE_SUCCESS = "@@asset/UPLOAD_IMAGE_SUCCESS",
  UPLOAD_IMAGE_FAILURE = "@@asset/UPLOAD_IMAGE_FAILURE",

  DELETE_IMAGE_REQUEST = "@@asset/DELETE_IMAGE_REQUEST",
  DELETE_IMAGE_SUCCESS = "@@asset/DELETE_IMAGE_SUCCESS",
  DELETE_IMAGE_FAILURE = "@@asset/DELETE_IMAGE_FAILURE",

  UPLOAD_AUDIO_REQUEST = "@@asset/UPLOAD_AUDIO_REQUEST",
  UPLOAD_AUDIO_SUCCESS = "@@asset/UPLOAD_AUDIO_SUCCESS",
  UPLOAD_AUDIO_FAILURE = "@@asset/UPLOAD_AUDIO_FAILURE",

  RENAME_IMAGE_REQUEST = "@@/asset/RENAME_IMAGE_REQUEST",
  RENAME_IMAGE_SUCCESS = "@@/asset/RENAME_IMAGE_SUCCESS",
  RENAME_IMAGE_FAILURE = "@@/asset/RENAME_IMAGE_FAILURE",
}

/**
 * Represents an asset that's just been selected from the user's
 * drive. This won't yet have anything like an id and the url won't
 * be final, so it needs to be different.
 */
export type UploadingAssets = { [id: string]: File };

export interface IAsset {
  id: number;
  name: string;
  url: string;
}

export interface IImage extends IAsset {
  type: "image";
}

export interface IAudio extends IAsset {
  type: "audio";
}

export interface AssetState {
  uploading: {
    images: UploadingAssets;
    audio: UploadingAssets;
  };
  images: { [id: number]: IImage };
  audio: { [id: number]: IAudio };
}
