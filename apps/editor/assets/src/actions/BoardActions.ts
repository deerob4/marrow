import { action } from "typesafe-actions";
import ActionType from "../constants";
import { UploadingAssets, Image, RenameAsset, Audio } from "../types";

export const editTileSize = (size: number) => {
  window.localStorage.setItem("boardTileSize", size.toString());
  return action(ActionType.EDIT_TILE_SIZE, size);
};

export const toggleShowArrows = () => action(ActionType.TOGGLE_SHOW_ARROWS);

export const toggleShowImages = () => action(ActionType.TOGGLE_SHOW_IMAGES);

export const toggleShowPathLines = () =>
  action(ActionType.TOGGLE_SHOW_PATH_LINES);

export const toggleShowUnusedTiles = () =>
  action(ActionType.TOGGLE_SHOW_UNUSED_TILES);
