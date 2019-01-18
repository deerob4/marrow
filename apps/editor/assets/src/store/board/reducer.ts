import { Reducer, combineReducers } from "redux";
import produce from "immer";
import {
  BoardActionType,
  BoardState,
  IBoardOptions,
  IBoardStructure,
  Traits
} from "./types";

import { Action } from "../index";
import { labelTrait, imageTrait, pathLineTrait } from "./traits";
import { Map } from "immutable";

const tileSize = window.localStorage.getItem("boardTileSize");

const traitMap: Map<number, Traits> = Map();

// const initialState: BoardState = {
//   structure: {
//     dimensions: { width: 10, height: 10 },
//     paths: []
//   },
//   options: {
//     tileSize: tileSize ? parseInt(tileSize, 10) : 40,
//     showPathLines: true,
//     showArrows: true,
//     showUnusedTiles: true
//   },
//   boardImages: {},
// };

const initialOptionsState: IBoardOptions = {
  tileSize: tileSize ? parseInt(tileSize, 10) : 40,
  showPathLines: true,
  showArrows: true,
  showUnusedTiles: true,
  showImages: true
};

const optionsReducer: Reducer<IBoardOptions> = (
  state = initialOptionsState,
  action: Action
) => {
  switch (action.type) {
    case BoardActionType.TOGGLE_SHOW_BOARD_PATH_LINES:
      return { ...state, showPathLines: !state.showPathLines };

    case BoardActionType.TOGGLE_SHOW_BOARD_ARROWS:
      return { ...state, showArrows: !state.showArrows };

    case BoardActionType.TOGGLE_SHOW_UNUSED_TILES:
      return { ...state, showUnusedTiles: !state.showUnusedTiles };

    case BoardActionType.TOGGLE_SHOW_IMAGES:
      return { ...state, showImages: !state.showImages };

    case BoardActionType.RESIZE_BOARD:
      return { ...state, tileSize: action.payload };

    default:
      return state;
  }
};

const initialStructureState: IBoardStructure = {
  dimensions: { width: 10, height: 10 },
  paths: []
};

const structureReducer: Reducer<IBoardStructure> = (
  state = initialStructureState,
  action: Action
) => {
  switch (action.type) {
    case BoardActionType.UPDATE_BOARD_STRUCTURE:
      return action.payload.board;

    default:
      return state;
  }
};

let image =
  "https://s3.eu-west-2.amazonaws.com/marrow-editor/images/ec5f30ea52bc422cb959d856a1324cc4.jpg";

const flReducer = (state = traitMap, action: Action) => {
  return state
    .set(23, { image: imageTrait(image) })
    .set(12, { image: imageTrait(image) })
    .set(18, { image: imageTrait(image) })
    .set(25, { image: imageTrait(image) })
    .set(17, { image: imageTrait(image) })
    .set(24, { image: imageTrait(image) })
    .set(32, { image: imageTrait(image) })
    .set(31, { image: imageTrait(image) })
    .set(40, { image: imageTrait(image) })
    .set(4, { pathLine: pathLineTrait({ x: 5, y: 0 }) })
    .set(22, { pathLine: pathLineTrait({ x: 5, y: 5 }) })
    .set(60, { pathLine: pathLineTrait({ x: 1, y: 5 }) })
    .set(26, { pathLine: pathLineTrait({ x: 1, y: 1 }) })
    .set(85, {
      labels: [
        labelTrait(
          "My Label",
          "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.    "
        ),
        labelTrait(
          "My Label",
          "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.    "
        )
      ]
    });
};

// const reducerd: Reducer<BoardState> = (
//   state = initialState,
//   action: Action
// ) => {
//   switch (action.type) {
//     case BoardActionType.RESIZE_BOARD:
//       return { ...state, tileSize: action.payload };

//     case BoardActionType.TOGGLE_SHOW_BOARD_PATH_LINES:
//       return { ...state, showPathLines: !state.showPathLines };

//     case BoardActionType.TOGGLE_SHOW_BOARD_ARROWS:
//       return { ...state, showArrows: !state.showArrows };

//     case BoardActionType.TOGGLE_SHOW_UNUSED_TILES:
//       return { ...state, showUnusedTiles: !state.showUnusedTiles };

//     case BoardActionType.UPDATE_BOARD_STRUCTURE:
//       return { ...state, structure: action.payload.board };

//     case ChannelActionType.CONNECT_TO_EDITOR:
//       return {
//         ...state,
//         structure: action.payload.gameData.board,
//         boardImages: action.payload.gameData.boardImages.reduce(
//           (images, { image, tile }) => ({
//             ...images,
//             [cantor(tile.x, tile.y)]: image
//           }),
//           {}
//         )
//       };

//     case GameActionType.RECOMPILE_GAME_SUCCESS:
//       return {
//         ...state,
//         boardImages: action.payload.boardImages.reduce(
//           (images, { image, tile }) => ({
//             ...images,
//             [cantor(tile.x, tile.y)]: image
//           }),
//           {}
//         )
//       };

//     case AuthActionType.SIGNOUT:
//       return initialState;

//     default:
//       return state;
//   }
// };

export const boardReducer = combineReducers({
  structure: structureReducer,
  options: optionsReducer,
  traits: flReducer
});
