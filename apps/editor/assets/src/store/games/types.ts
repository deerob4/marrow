import { IBoardStructure, IBoardImage, ICoord } from "../board/types";
import { ById } from "../../types";

export enum GameActionType {
  NEW_GAME_REQUEST = "@@game/NEW_GAME_REQUEST",
  NEW_GAME_SUCCESS = "@@game/NEW_GAME_SUCCESS",
  NEW_GAME_FAILURE = "@@game/NEW_GAME_FAILURE",

  LOAD_GAME = "@@game/LOAD_GAME",

  EDIT_GAME_SOURCE = "@@game/EDIT_GAME_SOURCE",

  DELETE_GAME_REQUEST = "@@game/DELETE_GAME_REQUEST",
  DELETE_GAME_SUCCESS = "@@game/DELETE_GAME_SUCCESS",
  DELETE_GAME_FAILURE = "@@game/DELETE_GAME_FAILURE",

  RECOMPILE_GAME_REQUEST = "@@game/RECOMPILE_GAME_REQUEST",
  RECOMPILE_GAME_SUCCESS = "@@game/RECOMPILE_GAME_SUCCESS",
  RECOMPILE_GAME_FAILURE = "@@game/RECOMPILE_GAME_FAILURE",

  TOGGLE_IS_PUBLIC = "@game/TOGGLE_IS_PUBLIC",

  CHANGE_HEADER_REQUEST = "@@game/CHANGE_HEADER_REQUEST",
  CHANGE_HEADER_SUCCESS = "@@game/CHANGE_HEADER_SUCCESS",
  CHANGE_HEADER_FAILURE = "@@game/CHANGE_HEADER_FAILURE",
}

export interface IGame {
  id: number;
  title: string;
  isPrivate: boolean;
  coverUrl: string;
}

export interface IEditingGame {
  loading: boolean;
  gameId: number;
  source: string;
  compileStatus: CompileStatus
}

interface OkStatus {
  type: "ok";
}

interface CompilingStatus {
  type: "compiling";
}

interface ErrorStatus {
  type: "error";
  error: string;
}

/**
 * The current status of the compilation process.
 */
export type CompileStatus = OkStatus | CompilingStatus | ErrorStatus;

/**
 * The repsonse received from the server upon successful
 * recompilation of the game, containing parsed details from the
 * game source code.
 */
export interface IRecompileResponse {
  board: IBoardStructure;
  boardImages: { image: string; tile: ICoord }[]
}

export interface GameState {
  byId: ById<IGame>
  allIds: number[]
}
