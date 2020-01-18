import { action, createAsyncAction } from "typesafe-actions";
import ActionType from "../constants";
import { GameMetadata, CompilationSuccess } from "../types";
import { push } from "connected-react-router";

/**
 * Asynchronous action for creating a new game.
 *
 * On `success`, this will carry a `GameMetadata` object holding
 * basic information about the new game.
 *
 * On `error`, the error message will be returned as a string.
 */
export const newGame = createAsyncAction(
  ActionType.NEW_GAME_REQUEST,
  ActionType.NEW_GAME_SUCCESS,
  ActionType.NEW_GAME_FAILURE
)<void, GameMetadata, string>();

/**
 * Asynchronous action for deleting a game.
 *
 * The `request` function takes the `id` of the game to be
 * deleted.
 *
 * On `error`, the error message will be returned as a string.
 */
export const deleteGame = createAsyncAction(
  ActionType.DELETE_GAME_REQUEST,
  ActionType.DELETE_GAME_SUCCESS,
  ActionType.DELETE_GAME_FAILURE
)<number, number, string>();

/**
 * Negates the `isPrivate` property of the game.
 */
export const toggleIsPublic = {
  request: () => action(ActionType.TOGGLE_GAME_VISIBILITY_REQUEST),
  result: (isPublic: boolean, gameId: number) =>
    action(ActionType.TOGGLE_GAME_VISIBILITY_RESULT, { isPublic, gameId })
};

export const loadGame = (gameId: number) => push(`/games/${gameId}`);
