const TOKEN_NAME = "authToken";

export default {
  /**
   * Retrieves the auth token, or `null` if it doesn't exist.
   */
  get() {
    return window.localStorage.getItem(TOKEN_NAME);
  },
  /**
   * Sets the authentication token so that it can be retrieved
   * when next needed.
   * @param token The new token to store.
   */
  set(token: string) {
    return window.localStorage.setItem(TOKEN_NAME, token);
  },
  /**
   * Removes the authentication token.
   */
  delete() {
    return window.localStorage.removeItem(TOKEN_NAME);
  }
};
