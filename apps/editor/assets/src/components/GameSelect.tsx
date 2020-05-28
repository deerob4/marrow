import React from "react";
import styled from "styled-components";
import { setEditingGameId } from "../actions/EditorActions";
import { GameMetadata } from "../types";
import { connect } from "react-redux";
import { Dispatch } from "redux";
import { push } from "connected-react-router";
import { deleteGame } from "../thunks/games";

interface Props {
  game: GameMetadata;
  loadGame: () => void;
  deleteGame: () => void;
  // deleteGame: () => void;
}

export const GameSelectContainer = styled.div`
  width: 175px;
  padding: 20px;
  box-shadow: 0px 10px 30px 0px rgba(0, 0, 0, 0.1);
  border-radius: 10px;
`;

export const GameThumbnail = styled.div`
  height: 150px;
  border-radius: 10px;
  /* border: 1px solid #ebebeb; */
  margin-bottom: 15px;
  background-image: url(${(props: { src: string }) => props.src});
  cursor: pointer;
`;

export const Title = styled.h3`
  text-align: center;
  font-size: 20px;
`;

const GameSelect: React.FC<Props> = ({ game, loadGame, deleteGame }) => {
  return (
    <GameSelectContainer key={game.id}>
      <GameThumbnail onClick={loadGame} src={game.coverUrl} />
      <Title>{game.title}</Title>
      <button onClick={deleteGame} className="btn btn-sm btn-secondary">
        Delete
      </button>
    </GameSelectContainer>
  );
};

const mapDispatchToProps = (dispatch: Dispatch, props: Props) => {
  return {
    loadGame: () => {
      dispatch(setEditingGameId(props.game.id));
      dispatch(push(`/games/${props.game.id}`));
    },
    deleteGame: () => {
      // @ts-ignore
      dispatch(deleteGame(props.game.id));
    }
  };
};

export default connect(() => ({}), mapDispatchToProps)(GameSelect);
