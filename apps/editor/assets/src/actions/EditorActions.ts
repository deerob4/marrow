import { action, createAsyncAction } from "typesafe-actions";
import ActionType from "../constants";
import { EditorConnect, CompilationSuccess } from "../types";


export const connectToEditor = createAsyncAction(
  ActionType.EDITOR_CONNECT_REQUEST,
  ActionType.EDITOR_CONNECT_SUCCESS,
  ActionType.EDITOR_CONNECT_FAILURE
)<number, EditorConnect, string>();

// export const connectToEditor = (data: EditorConnect) =>
//   action(ActionType.EDITOR_CONNECT, data);

export const leaveEditor = () => action(ActionType.EDITOR_LEAVE);

/**
 * Updates the game's source code.
 * @param newSource The new game source code.
 */
export const editGameSource = (
  gameId: number,
  newSource: string,
  broadcast = true
) => action(ActionType.EDIT_GAME_SOURCE, { gameId, newSource, broadcast });

export const recompile = {
  /**
   * Request to recompile the game.
   */
  request: () => action(ActionType.RECOMPILE_REQUEST),
  /**
   * The game was successfully recompiled.
   */
  success: (data: CompilationSuccess) =>
    action(ActionType.RECOMPILE_SUCCESS, data),
  /**
   * A compilation error prevented the game from compiling.
   */
  failure: (error: string) => action(ActionType.RECOMPILE_FAILURE, error)
};

export const setEditingGameId = (gameId: number) =>
  action(ActionType.SET_EDITING_GAME_ID, gameId);
