import { Action, BoardOptions, Dimensions, Path, BoardState } from "../types";
import ActionType from "../constants";
import { assoc } from "ramda";
import { combineReducers } from "redux";

const defaultOptions: () => BoardOptions = () => {
  const tileSize = window.localStorage.getItem("boardTileSize");

  return {
    tileSize: tileSize ? parseInt(tileSize, 10) : 40,
    showArrows: true,
    showImages: true,
    showPathLines: true,
    showUnusedTiles: true
  };
};

function options(options: BoardOptions = defaultOptions(), action: Action) {
  switch (action.type) {
    case ActionType.EDIT_TILE_SIZE:
      return assoc("tileSize", action.payload, options);

    case ActionType.TOGGLE_SHOW_ARROWS:
      return assoc("showArrows", !options.showArrows, options);

    case ActionType.TOGGLE_SHOW_IMAGES:
      return assoc("showImages", !options.showImages, options);

    case ActionType.TOGGLE_SHOW_PATH_LINES:
      return assoc("showPathLines", !options.showPathLines, options);

    case ActionType.TOGGLE_SHOW_UNUSED_TILES:
      return assoc("showUnusedTiles", !options.showUnusedTiles, options);

    default:
      return options;
  }
}

function dimensions(
  state: Dimensions = { width: 0, height: 0 },
  action: Action
) {
  switch (action.type) {
    case ActionType.EDITOR_CONNECT_SUCCESS:
    case ActionType.RECOMPILE_SUCCESS:
      return action.payload.board.dimensions;

    default:
      return state;
  }
}

function paths(state: Path[] = [], action: Action): Path[] {
  switch (action.type) {
    case ActionType.EDITOR_CONNECT_SUCCESS:
    case ActionType.RECOMPILE_SUCCESS:
      return action.payload.board.paths;

    default:
      return state;
  }
}

export default combineReducers<BoardState, Action>({
  options,
  dimensions,
  paths
});
