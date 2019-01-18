import * as ReactDOM from "react-dom";
import * as React from "react";
import { useReducer } from "react";
import { action, ActionType, createAsyncAction } from "typesafe-actions";
import axios from "axios";
import { snakeCase, mapKeys } from "lodash";
import { GameInfo } from "./GameInfo";
import { HostSuccessPanel } from "./HostSuccessPanel";
import { ConfigForm, Config } from "./ConfigForm";

export interface Game {
  id: number;
  title: string;
  author: string;
  description: string | null;
  minPlayers: number;
  maxPlayers: number;
}

interface GSProps {
  games: Game[];
  selected: number;
  onChange: (id: number) => void;
}

const GameSelect: React.SFC<GSProps> = props => {
  function onChange(e: React.ChangeEvent<HTMLSelectElement>) {
    const id = parseInt(e.target.value, 10);
    return props.onChange(id);
  }

  return (
    <div className="form-group">
      <label htmlFor="game">Choose a game:</label>
      <select
        className="form-control"
        onChange={onChange}
        value={props.selected}
        name="game"
        id="game">
        {props.games.map(({ id, title }) => (
          <option key={id} value={id}>
            {title}
          </option>
        ))}
      </select>
    </div>
  );
};

enum AppMsg {
  InitialiseGameMap = "INITIALISE_GAME_MAP",
  SelectGame = "SELECT_GAME",
  FetchRequest = "FETCH_REQUEST",
  FetchSuccess = "FETCH_SUCCESS",
  FetchFailure = "FETCH_FAILURE"
}

const AppActions = {
  selectGame(id: number) {
    return action(AppMsg.SelectGame, id);
  },
  initialiseGameMap(games: Game[]) {
    return action(AppMsg.InitialiseGameMap, games);
  },
  fetchGame: createAsyncAction(
    AppMsg.FetchRequest,
    AppMsg.FetchSuccess,
    AppMsg.FetchFailure
  )<void, string, void>()
};

type AppAction = ActionType<typeof AppActions>;

interface State {
  selectedGame: number;
  validForm: boolean;
  isFetchingUrl: boolean;
  url: string | null;
  games: { [id: number]: Game };
  fetchError: string | null;
}

interface AppProps {
  games: Game[];
}

const defaultState: State = {
  selectedGame: 0,
  validForm: true,
  games: {},
  isFetchingUrl: false,
  fetchError: null,
  url: null
};

function updateState(state: State, action: AppAction): State {
  switch (action.type) {
    case AppMsg.InitialiseGameMap:
      return {
        ...state,
        selectedGame: action.payload[0].id,
        games: action.payload.reduce(
          (map, game) => ({ ...map, [game.id]: game }),
          {}
        )
      };

    case AppMsg.SelectGame:
      return { ...state, selectedGame: action.payload };

    case AppMsg.FetchRequest:
      return { ...state, isFetchingUrl: true, fetchError: null };

    case AppMsg.FetchSuccess:
      return { ...state, url: action.payload };

    case AppMsg.FetchFailure:
      return {
        ...state,
        fetchError: "Failed to host your game. Please try again later.",
        isFetchingUrl: false
      };
  }
}

const HostGame: React.SFC<AppProps> = ({ games }) => {
  const [state, dispatch] = useReducer(
    updateState,
    defaultState,
    games.length ? AppActions.initialiseGameMap(games) : null
  );

  function hostGame(config: Config) {
    dispatch(AppActions.fetchGame.request());

    const payload = {
      game_id: state.selectedGame,
      configuration: mapKeys(config, (v, k) => snakeCase(k))
    };

    axios
      .post("/api/hosted-games", payload)
      .then(r => dispatch(AppActions.fetchGame.success(r.data.data.id)))
      .catch(() => dispatch(AppActions.fetchGame.failure()));
  }

  return (
    <div className="hero-container">
      <div className="hero-modal">
        <h1 className="logo">Marrow</h1>
        <h2 className="hero-modal__title">Host Game</h2>

        {Object.keys(state.games).length ? (
          !state.url ? (
            <>
              <p>
                You can host a game to play online against others. Select one below
                and get playing!
              </p>
              <GameSelect
                selected={state.selectedGame}
                games={games}
                onChange={id => dispatch(AppActions.selectGame(id))}
              />
              <GameInfo {...state.games[state.selectedGame]} />
              {state.fetchError && <p className="text-danger">{state.fetchError}</p>}
              <ConfigForm isFetching={state.isFetchingUrl} onSubmit={hostGame} />
            </>
          ) : (
            <HostSuccessPanel gameUrl={state.url} />
          )
        ) : (
          <p className="mb-0">No games available.</p>
        )}
      </div>
    </div>
  );
};

export function render() {
  const target = document.getElementById("app");
  const gameJson: string = (window as any).__GAMES__;
  const games: Game[] = JSON.parse(gameJson);

  ReactDOM.render(<HostGame games={games} />, target);
}
