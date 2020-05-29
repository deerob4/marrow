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

const GameIndex: React.FC<Props> = (props) => {
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
  const games = state.gameMetadata.allIds.map(
    (id) => state.gameMetadata.byId[id]
  );
  return { games };
};

const mapDispatchToProps = { newGame: newGame, deleteGame: () => null };

export default connect(mapStateToProps, mapDispatchToProps)(GameIndex);
