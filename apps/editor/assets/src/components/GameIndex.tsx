import React from "react";
import { connect } from "react-redux";
import styled from "styled-components";
import GameSelect from "./GameSelect";
import { useTitle } from "../hooks/useTitle";
import { AppState, GameMetadata } from "../types";
import Navbar from "./Navbar";
import { newGame } from "../thunks/games";

interface Props {
  games: GameMetadata[];
  newGame: () => void;
  deleteGame: (id: number) => void;
}

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
  grid-template-columns: repeat(auto-fill, 175px);
  grid-gap: 20px;
`;

const Title = styled.h1`
  font-size: 25px;
  text-transform: uppercase;
  font-weight: bold;
  letter-spacing: 1.2px;
`;

const TopRow = styled.div`
  display: flex;
  justify-content: space-between;
  margin-bottom: 10px;
`;

const GameIndex: React.SFC<Props> = (props) => {
  useTitle("Your Games");

  return (
    <>
      <Navbar />
      <div className="container">
        <TopRow>
          <Title>Your Games</Title>
          <div className="btn btn-primary" onClick={props.newGame}>
            New Game
          </div>
        </TopRow>

        <GameGrid>
          {props.games.map((game) => (
            // @ts-ignore
            <GameSelect
              key={game.id}
              game={game}
              // deleteGame={() => props.deleteGame(game.id)}
            />
          ))}
        </GameGrid>
      </div>
    </>
  );
};

const mapStateToProps = (state: AppState) => {
  let games = state.gameMetadata.allIds.map((id) => state.gameMetadata.byId[id]);
  return { games };
};

const mapDispatchToProps = { newGame: newGame, deleteGame: () => null };

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(GameIndex);
