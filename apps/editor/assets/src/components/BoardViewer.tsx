import React from "react";
import Card from "./Card";
import Board from "./Board";
import BoardControls from "./Board/BoardControls";

const BoardViewer: React.FC<unknown> = () => {
  return (
    <Card title="Board Viewer" headerType="outside">
      <BoardControls />
      <Board />
    </Card>
  );
};

export default BoardViewer;
