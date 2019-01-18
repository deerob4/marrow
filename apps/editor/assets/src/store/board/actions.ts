import { action } from "typesafe-actions";
import { BoardActionType, IBoardStructure } from "./types";

export const resizeBoard = (newSize: number) =>
  action(BoardActionType.RESIZE_BOARD, newSize);

export const toggleShowPathLines = () =>
  action(BoardActionType.TOGGLE_SHOW_BOARD_PATH_LINES);

export const updateBoardStructure = (board: IBoardStructure) =>
  action(BoardActionType.UPDATE_BOARD_STRUCTURE, { board });

export const toggleShowArrows = () =>
  action(BoardActionType.TOGGLE_SHOW_BOARD_ARROWS);

export const toggleShowUnusedTiles = () =>
  action(BoardActionType.TOGGLE_SHOW_UNUSED_TILES);

export const toggleShowImages = () =>
  action(BoardActionType.TOGGLE_SHOW_IMAGES);
