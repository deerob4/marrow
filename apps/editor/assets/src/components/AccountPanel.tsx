import React, { Dispatch } from "react";
import styled from "styled-components";
import { RouteComponentProps } from "react-router";
import { connect } from "react-redux";

import GameSelect from "./GameSelect";
import Icon from "./Icon";
import { loadGame } from "../actions/GameActions";
import { deleteGame, newGame } from "../thunks/games";
import { logout } from "../thunks/auth";

import { GameMetadata } from "../types";

interface Props extends RouteComponentProps {
  games: GameMetadata[];
  newGame: typeof newGame;
  deleteGame: typeof deleteGame;
  signout: typeof logout;
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

const AccountPanel: React.FC<Props> = (props) => {
  function navigateToGame(gameId: number) {
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
        {props.games.map((game: GameMetadata) => (
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

function mapStateToProps(state: any) {
  return { games: Object.values(state.games.games) as GameMetadata[] };
}

function mapDispatchToProps(dispatch: any) {
  return {
    newGame: () => dispatch(newGame()),
    deleteGame: (gameId: number) => dispatch(deleteGame(gameId))
  };
}

export default connect(mapStateToProps, mapDispatchToProps)(AccountPanel);
