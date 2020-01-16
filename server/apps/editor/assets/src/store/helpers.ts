import { AppState } from "./index";

export const authToken = (getState: () => AppState) => getState().auth.token;

export const headerConfig = (token: string) => ({
  headers: { Authorization: "bearer " + token }
});
