export const enum AuthActionType {
  LOGIN_REQUEST = "@@auth/LOGIN_REQUEST",
  LOGIN_SUCCESS = "@@auth/LOGIN_SUCCESS",
  LOGIN_FAILURE = "@@auth/LOGIN_FAILURE",

  SIGNUP_REQUEST = "@@auth/SIGNUP_REQUEST",
  SIGNUP_SUCCESS = "@@auth/SIGNUP_SUCCESS",
  SIGNUP_FAILURE = "@@auth/SIGNUP_FAILURE",

  SIGNOUT = "@@auth/SIGNOUT",

  FETCH_ACCOUNT_DETAILS_REQUEST = "@@auth/FETCH_ACCOUNT_DETAILS_REQUEST",
  FETCH_ACCOUNT_DETAILS_SUCCESS = "@@auth/FETCH_ACCOUNT_DETAILS_SUCCESS",
  FETCH_ACCOUNT_DETAILS_FAILURE = "@@auth/FETCH_ACCOUNT_DETAILS_FAILURE",

  LOADING_FINISHED = "@@auth/LOADING_FINISHED"
}

export interface IUser {
  id: string;
  name: string;
  email: string;
}

export type AuthStatus = "none" | "loggingIn" | "signingUp"


export interface AuthState {
  readonly loginError: string;
  readonly signupError: string;
  readonly status: AuthStatus,
  readonly user: IUser | undefined;
  readonly token: string;
}
