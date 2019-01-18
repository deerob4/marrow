import api from "../../api";

import {
  login as loginAction,
  signup as signupAction,
  signout as signoutAction,
  fetchAccountDetails as fetchAccountDetailsAction,
  loadFinished as loadFinishedAction
} from "./actions";

import { AppState } from "../index";
import { Dispatch } from "redux";
import { authToken, headerConfig } from "../helpers";
import { connectToSocket } from "../channels/thunks";

export interface ILoginCredentials {
  email: string;
  password: string;
}

export interface IAccountDetails {
  name: string;
  email: string;
  password: string;
}

export function login(credentials: ILoginCredentials) {
  return (dispatch: Dispatch) => {
    dispatch(loginAction.request());

    api
      .post("/session", { credentials })
      .then(r => {
        const { user, token, games } = r.data.data;
        // saveToken(token);
        dispatch(loginAction.success({ user, games, token }));
      })
      .catch(e => {
        dispatch(loginAction.failure("Invalid email address or password."));
      });
  };
}

export function signup(account: IAccountDetails) {
  return (dispatch: Dispatch) => {
    dispatch(signupAction.request());

    api
      .post("/accounts", { account })
      .then(r => {
        const { user, token, games } = r.data.data;
        // saveToken(token);
        dispatch(signupAction.success({ user, token, games }));
      })
      .catch(e => {
        const errorMessage = e.response.data.data;
        dispatch(signupAction.failure(errorMessage));
      });
  };
}

export function fetchAccountDetails() {
  return (dispatch: Dispatch, getState: () => AppState) => {
    const token = getToken();

    if (token) {
      api
        .get("/account", headerConfig(token))
        .then(r => {
          const { user, games } = r.data.data;

          dispatch(
            fetchAccountDetailsAction.success({
              user: user.data,
              games: games.data,
              token
            })
          );
          dispatch(connectToSocket());
          dispatch(loadFinishedAction());
        })
        .catch(e => {
          // The token must have been invalidated, so delete it from
          // storage.
          const errorMessage = e.response.data.data;
          console.error(e.response);
          dispatch(fetchAccountDetailsAction.failure(errorMessage));
          dispatch(loadFinishedAction());
          deleteToken();
        });
    } else {
      dispatch(loadFinishedAction());
    }
  };
}

export function signout() {
  return (dispatch: Dispatch, getState: () => AppState) => {
    const token = authToken(getState);
    api.delete("/session", headerConfig(token));
    dispatch(signoutAction());
    deleteToken();
  };
}

// If they open a game directly from the URL instead of arriving
// at it via an interal link, we need to get the game id so that
// it can be passed to currentGame in the games reducer.
function extractGameId(path: string) {
  const regex = /\/games\/(.+)/gm;
  const match = regex.exec(path);

  if (!match || match.length !== 2) return "";

  return match[1];
}

function saveToken(token: string) {
  window.localStorage.setItem("token", token);
}

function deleteToken() {
  window.localStorage.removeItem("token");
}

function getToken() {
  return window.localStorage.getItem("token");
}
