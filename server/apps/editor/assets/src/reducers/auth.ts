import { AuthStatus, Action, AuthState } from "../types";
import ActionType from "../constants";
import { combineReducers } from "redux";
import { LOCATION_CHANGE } from "connected-react-router";

function status(state: AuthStatus = "idle", action: Action): AuthStatus {
  switch (action.type) {
    case ActionType.LOGIN_REQUEST:
      return "loggingIn";

    case ActionType.SIGNUP_REQUEST:
      return "signingUp";

    case ActionType.LOGIN_SUCCESS:
    case ActionType.LOGIN_FAILURE:
    case ActionType.SIGNUP_SUCCESS:
    case ActionType.SIGNUP_FAILURE:
      return "idle";

    default:
      return state;
  }
}

function error(state: string | null = null, action: Action) {
  switch (action.type) {
    case ActionType.LOGIN_FAILURE:
    case ActionType.SIGNUP_FAILURE:
      return action.payload;

    case ActionType.LOGIN_REQUEST:
    case ActionType.SIGNUP_REQUEST:
    case LOCATION_CHANGE:
      return null;

    default:
      return state;
  }
}

function loggedIn(state = false, action: Action) {
  switch (action.type) {
    case ActionType.LOGIN_SUCCESS:
      return true;

    case ActionType.LOGOUT:
      return false;

    default:
      return state;
  }
}

function token(state = "", action: Action) {
  switch (action.type) {
    case ActionType.LOGIN_SUCCESS:
      return action.payload.token;

    default:
      return state;
  }
}

function isCheckingSession(state = true, action: Action) {
  switch (action.type) {
    case ActionType.LOGIN_SUCCESS:
    case ActionType.LOGIN_FAILURE:
    case ActionType.FINISH_SESSION_CHECK:
      return false;

    default:
      return state;
  }
}

export default combineReducers<AuthState, Action>({
  status,
  error,
  loggedIn,
  token,
  isCheckingSession
});
