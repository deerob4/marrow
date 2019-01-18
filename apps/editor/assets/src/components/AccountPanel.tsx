import * as React from "react";
import styled from "styled-components";
import { RouteComponentProps } from "react-router";
import { connect } from "react-redux";
import { AppState } from "../store";
import { useTitle } from "../hooks/useTitle";
import GameSelect from "./GameSelect";
import Icon from "./Icon";
import { loadGame } from "../store/games/actions";
import { deleteGame, newGame } from "../store/games/thunks";
import { signout } from "../store/auth/thunks";

import { IGame, GameState } from "../store/games/types";

interface Props extends RouteComponentProps {
  games: IGame[];
  newGame: typeof newGame;
  deleteGame: typeof deleteGame;
  signout: typeof signout;
  show: boolean;
  close: () => void;
}

const OutModal = styled.div`
  position: absolute;
  top: 0;
  left: 0;
  bottom: 0;
  right: 0;
  z-index: 2;
  background-color: rgba(0, 0, 0, 0.5);
`;

const AccountPanelContainer = styled.div`
  width: 720px;
  border-radius: 5px;
  padding: 30px;
  background-color: #fff;
  position: absolute;
  top: 25%;
  left: 28%;
  right: 10%;
`;

const GameGrid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fill, 150px);
  grid-gap: 20px;
`;

const AccountTitleBar = styled.div`
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 25px;
`;

const AccountPanel: React.SFC<Props> = props => {
  function navigateToGame(gameId: string) {
    loadGame(gameId);
  }

  function renderAddGameButton() {
    return (
      <div>
        <button className="btn btn-primary" onClick={props.newGame}>
          <span className="mr-2">Add Game</span>
          <Icon name="plus" />
        </button>
      </div>
    );
  }

  function renderGames() {
    if (!props.games.length) {
      return (
        <>
          <h3>No games yet. </h3>
          {renderAddGameButton()}
        </>
      );
    }

    return (
      <GameGrid>
        {props.games.map(game => (
          <GameSelect
            key={game.id}
            game={game}
            loadGame={() => navigateToGame(game.id)}
            deleteGame={() => props.deleteGame(game.id)}
          />
        ))}
      </GameGrid>
    );
  }

  if (!props.show) return null;

  return (
    <OutModal>
      <AccountPanelContainer>
        <AccountTitleBar>
          <h1>Your Games</h1>
          <div>
            {props.games.length ? renderAddGameButton() : null}
            <div className="btn btn-secondary" onClick={() => props.close()}>
              Close
            </div>
          </div>
        </AccountTitleBar>

        {renderGames()}
      </AccountPanelContainer>
    </OutModal>
  );
};

function mapStateToProps(state: AppState) {
  return { games: Object.values(state.games.games) };
}

const mapDispatchToProps = { newGame, deleteGame, signout };

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(AccountPanel);
