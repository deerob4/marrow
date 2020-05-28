import React from "react";
import Card from "./Card";
import Board from "./Board";
import BoardControls from "./Board/BoardControls";

interface Props {}

const BoardViewer: React.FC<Props> = (props) => {
  return (
    <Card title="Board Viewer" headerType="outside">
      <BoardControls />
      <Board />
    </Card>
  );
};

export default BoardViewer;
