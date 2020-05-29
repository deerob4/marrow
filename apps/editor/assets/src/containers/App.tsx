import React from "react";
import { Route, Redirect, Switch } from "react-router-dom";
import { connect } from "react-redux";
import Editor from "../components/Editor";
import GameIndex from "../components/GameIndex";
import Auth from "../components/Auth";
import { AppState } from "../types";
import { loadSession } from "../thunks/auth";
import { setEditingGameId } from "../actions/EditorActions";

interface Props {
  isCheckingSession: boolean;
  loggedIn: boolean;
  loadSession: () => void;
  setEditingGameId: (gameId: number) => void;
  gameExists: (gameId: number) => boolean;
  url: string;
}

class App extends React.Component<Props, unknown> {
  constructor(props: Props) {
    super(props);
  }

  componentDidMount() {
    this.props.loadSession();

    // If they arrive at the app directly via a game url, we need to
    // set the game id so that the editor knows what to connect to.
    const gameId = extractGameId(this.props.url);
    if (gameId) {
      this.props.setEditingGameId(gameId);
    }
  }

  render() {
    // TODO: show a loading screen here if the check takes too long.
    if (this.props.isCheckingSession) return null;

    if (!this.props.loggedIn) {
      return <Route path="/" component={Auth} />;
    }

    return (
      <Switch>
        <Route
          path="/games/:gameId"
          render={(props) => {
            if (props.match) {
              const { gameId } = props.match.params;
              if (this.props.gameExists(gameId)) {
                return <Editor {...props} />;
              } else {
                return <Redirect to="/games" />;
              }
            }
          }}
        />
        <Route path="/games" component={GameIndex} />
        <Route render={() => <Redirect to="/games" />} />
      </Switch>
    );
  }
}

function extractGameId(url: string) {
  const regex = /\/games\/(\d+)$/;
  const match = url.match(regex);

  if (match) {
    const gameId = match[1];
    return parseInt(gameId, 10);
  }
}

const mapStateToProps = (state: AppState) => ({
  isCheckingSession: state.auth.isCheckingSession,
  loggedIn: state.auth.loggedIn,
  url: state.router.location.pathname,
  gameExists: (gameId: number) => state.gameMetadata.byId[gameId] !== undefined
});

const mapDispatchToProps = {
  loadSession,
  setEditingGameId
};

export default connect(mapStateToProps, mapDispatchToProps)(App);
