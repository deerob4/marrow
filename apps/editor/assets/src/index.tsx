import { render } from "react-dom";
import * as React from "react";
import { Provider } from "react-redux";
import { ConnectedRouter } from "connected-react-router";
import configureStore, { history } from "./configureStore";

import App from "./containers/App";

import "../css/app.scss";

const element = document.getElementById("app");

const initialState: any = {};

const store = configureStore(initialState);

render(
  <Provider store={store}>
    <ConnectedRouter history={history}>
      <App />
    </ConnectedRouter>
  </Provider>,
  element
);
