import { combineReducers } from "redux";
import { AuthActionType, AuthState, IUser, AuthStatus } from "./types";
import { ActionType, action } from "typesafe-actions";
import * as actions from "./actions";

type Action = ActionType<typeof actions>;

const userReducer = (user: IUser | undefined = undefined, action: Action) => {
  switch (action.type) {
    case AuthActionType.LOGIN_SUCCESS:
      return action.payload.user;

    case AuthActionType.SIGNUP_SUCCESS:
      return undefined;

    default:
      return user;
  }
};

const actionReducer = (state: AuthStatus = "none", action: Action) => {
  switch (action.type) {
    case AuthActionType.SIGNUP_REQUEST:
      return "signingUp";

    case AuthActionType.LOGIN_REQUEST:
      return "loggingIn";

    case AuthActionType.LOGIN_FAILURE:
    case AuthActionType.SIGNUP_FAILURE:
    case AuthActionType.LOGIN_SUCCESS:
    case AuthActionType.SIGNUP_SUCCESS:
      return "none";

    default:
      return state;
  }
};

const tokenReducer = (token = "", action: Action) => {
  switch (action.type) {
    case AuthActionType.LOGIN_SUCCESS:
      return action.payload.token;

    default:
      return token;
  }
};

const loginErrorReducer = (error = "", action: Action) => {
  switch (action.type) {
    case AuthActionType.LOGIN_FAILURE:
      return action.payload;

    default:
      return error;
  }
};

const signupErrorReducer = (error = "", action: Action) => {
  switch (action.type) {
    case AuthActionType.SIGNUP_FAILURE:
      return action.payload;

    default:
      return error;
  }
};

const reducer = combineReducers<AuthState, Action>({
  loginError: loginErrorReducer,
  signupError: signupErrorReducer,
  status: actionReducer,
  user: userReducer,
  token: tokenReducer
});

export { reducer as authReducer };
