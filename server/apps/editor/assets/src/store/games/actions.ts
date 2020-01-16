import { action, createAsyncAction } from "typesafe-actions";
import { GameActionType, IGame, IRecompileResponse } from "./types";
import { string } from "prop-types";

export const newGame = createAsyncAction(
  GameActionType.NEW_GAME_REQUEST,
  GameActionType.NEW_GAME_SUCCESS,
  GameActionType.NEW_GAME_FAILURE
)<void, IGame, string>();

export const loadGame = (id: string) => action(GameActionType.LOAD_GAME, id);

export const deleteGame = createAsyncAction(
  GameActionType.DELETE_GAME_REQUEST,
  GameActionType.DELETE_GAME_SUCCESS,
  GameActionType.DELETE_GAME_FAILURE
)<string, string, string>();

export const recompileGame = createAsyncAction(
  GameActionType.RECOMPILE_GAME_REQUEST,
  GameActionType.RECOMPILE_GAME_SUCCESS,
  GameActionType.RECOMPILE_GAME_FAILURE
)<void, IRecompileResponse, string>();

export const editGameSource = (gameId: string, newSource: string) =>
  action(GameActionType.EDIT_GAME_SOURCE, { gameId, newSource });

export const toggleIsPublic = (isPublic: boolean) =>
  action(GameActionType.TOGGLE_IS_PUBLIC, isPublic);

export const changeHeader = createAsyncAction(
  GameActionType.CHANGE_HEADER_REQUEST,
  GameActionType.CHANGE_HEADER_SUCCESS,
  GameActionType.CHANGE_HEADER_FAILURE
)<void, string, string>();
