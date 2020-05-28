import { Dispatch } from "redux";
import { capitalize } from "lodash";
import api from "../api";
import { SignupFields, LoginCredentials, AppState } from "../types";
import * as actions from "../actions/AuthActions";
import TokenStore from "./TokenStore";

export function signup(account: SignupFields) {
  return (dispatch: Dispatch) => {
    dispatch(actions.signup.request());

    api
      .post("/accounts", { account })
      .then((r) => dispatch(actions.login.success(r.data.data)))
      .catch((e) =>
        dispatch(actions.login.failure(errorString(e.response.data.errors)))
      );
  };
}

function errorString(errors: { [field: string]: string[] }) {
  const start =
    "There were problems encountered with your details:<ul style='padding-left:0;margin-bottom:0;padding-top:5px;'>";

  let x = Object.keys(errors).reduce((message, field) => {
    const error = `<li style="list-style-type:none;">${capitalize(field)}: ${
      errors[field][0]
    }</li>`;
    return message + error;
  }, start);

  return x + "</ul>";
}

export function login(credentials: LoginCredentials) {
  return (dispatch: Dispatch) => {
    dispatch(actions.login.request());

    api
      .post("/sessions", { credentials })
      .then((r) => dispatch(actions.login.success(r.data.data)))
      .catch((e) => {
        const message =
          e.response.status === 401
            ? "Invalid email address or password."
            : "Internal server error.";
        dispatch(actions.login.failure(message));
      });
  };
}

export function loadSession() {
  return (dispatch: Dispatch) => {
    const token = TokenStore.get();

    if (token) {
      api
        .get(`/sessions/${token}`)
        .then((r) => {
          try {
            dispatch(actions.login.success(r.data.data));
          } catch {
            console.error(r);
          }
        })
        .catch(() => dispatch(actions.login.failure("Invalid token")));
    } else {
      dispatch(actions.finishCheckingSession());
    }
  };
}

export function logout() {
  return (dispatch: Dispatch, getState: () => AppState) => {
    const token = getState().auth.token;
    dispatch(actions.logout());
    api.delete(`/sessions/${token}`);
  };
}
