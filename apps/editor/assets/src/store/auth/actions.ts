import { action, createAsyncAction } from "typesafe-actions";
import { AuthActionType, IUser } from "./types";
import { IGame } from "../games/types";

interface ILoginSuccess {
  token: string;
  user: IUser;
  games: IGame[];
}

export const signup = createAsyncAction(
  AuthActionType.SIGNUP_REQUEST,
  AuthActionType.SIGNUP_SUCCESS,
  AuthActionType.SIGNUP_FAILURE
)<void, ILoginSuccess, string>();

export const login = createAsyncAction(
  AuthActionType.LOGIN_REQUEST,
  AuthActionType.LOGIN_SUCCESS,
  AuthActionType.LOGIN_FAILURE
)<void, ILoginSuccess, string>();

export const fetchAccountDetails = createAsyncAction(
  AuthActionType.FETCH_ACCOUNT_DETAILS_REQUEST,
  AuthActionType.FETCH_ACCOUNT_DETAILS_SUCCESS,
  AuthActionType.FETCH_ACCOUNT_DETAILS_FAILURE
)<void, ILoginSuccess, string>();

export const signout = () => action(AuthActionType.SIGNOUT);

export const loadFinished = () => action(AuthActionType.LOADING_FINISHED);
