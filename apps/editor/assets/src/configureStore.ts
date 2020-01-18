import { Store, createStore, applyMiddleware, Middleware } from "redux";
import { routerMiddleware } from "connected-react-router";
import { createBrowserHistory } from "history";
import { composeWithDevTools } from "redux-devtools-extension";
import thunk from "redux-thunk";

import { createRootReducer } from "./reducers";
import { AppState } from "./types";
import { authMiddleware, socketMiddleware } from "./middleware";

export const history = createBrowserHistory();

const composeEnhancers = composeWithDevTools({});

export default function configureStore(initialState: AppState): Store<AppState> {
  const store = createStore(
    createRootReducer(history),
    initialState,
    composeEnhancers(
      applyMiddleware(
        routerMiddleware(history),
        thunk.withExtraArgument(10),
        authMiddleware,
        socketMiddleware
      )
    )
  );

  return store;
}
