import { action, createAsyncAction } from "typesafe-actions";
import ActionType from "../constants";
import { AfterLogin } from "../types";

/**
 * Aysynchronous action for creating a new account.
 *
 * This doesn't return anything on signup success, because it is
 * expected that the `login` action will be called directly
 * after.
 */
export const signup = createAsyncAction(
  ActionType.SIGNUP_REQUEST,
  ActionType.SIGNUP_SUCCESS,
  ActionType.SIGNUP_FAILURE
)<void, void, string>();

/**
 * Aysynchronous action for signing in.
 */
export const login = createAsyncAction(
  ActionType.LOGIN_REQUEST,
  ActionType.LOGIN_SUCCESS,
  ActionType.LOGIN_FAILURE
)<void, AfterLogin, string>();

export const logout = () => action(ActionType.LOGOUT);

export const finishCheckingSession = () =>
  action(ActionType.FINISH_SESSION_CHECK);

export const setEditingGameId = (gameId: number) =>
  action(ActionType.SET_EDITING_GAME_ID, gameId);
