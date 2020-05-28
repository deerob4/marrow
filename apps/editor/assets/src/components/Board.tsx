import React from "react";
import styled from "styled-components";

import { IDimensions, ICoord, IPathLine, IBoardStructure } from "../types";
import Coordinate from "./Board/Coordinate";
import Tile from "./Board/Tile";
import EmptyTile from "./Board/EmptyTile";
import * as R from "ramda";
import { always, cond, equals, complement, allPass, where } from "ramda";
import notEquals from "../utils/notEqual";
import { connect } from "react-redux";
import { AppState } from "../types";

type Tile = [ICoord, IPathLine | null];

interface Props {
  structure: IBoardStructure;
  tileSize: number;
}

const BoardStyleContainer = styled.div`
  display: grid;
  margin-top: 15px;
  grid-template-columns: repeat(
    ${(props: { width: number; tileSize: number }) => props.width + 1},
    ${(props: { tileSize: number }) => props.tileSize + "px"}
  );
`;

export const lineWidth = (arrow: ILineStyle) => arrow.distance * arrow.tileSize;

export interface ILineStyle {
  distance: number;
  tileSize: number;
}

const tileKey = (coord: ICoord) => `(${coord.x},${coord.y})`;

const Board: React.FC<Props> = ({ structure, tileSize }) => {
  return (
    <BoardStyleContainer width={structure.dimensions.width} tileSize={tileSize}>
      {renderTiles(structure.dimensions)}
    </BoardStyleContainer>
  );
};

type CoordPredicate = (coord: ICoord) => boolean;

const iSYCoord: CoordPredicate = where({
  x: equals(0),
  y: notEquals(0)
});

const isXCoord: CoordPredicate = where({
  x: notEquals(0),
  y: equals(0)
});

const isEmptyTile: CoordPredicate = allPass([
  complement(iSYCoord),
  complement(isXCoord),
  where({ y: equals(0) })
]);

const renderTile = cond([
  [isXCoord, ({ x }) => <Coordinate key={`x-${x}`} value={x - 1} />],
  [iSYCoord, ({ y }) => <Coordinate key={`y-${y}`} value={y - 1} />],
  [isEmptyTile, always(<EmptyTile key="empty-tile" />)],
  // @ts-ignore
  [R.T, (coord) => <Tile key={tileKey(coord)} coord={coord} />]
]);

const renderTiles = (dimensions: IDimensions) => {
  const tiles: JSX.Element[] = [];

  for (let y = 0; y <= dimensions.height; y++) {
    for (let x = 0; x <= dimensions.width; x++) {
      const tile = renderTile({ x, y });
      tiles.push(tile);
    }
  }

  return tiles;
};

const mapStateToProps = (state: AppState) => ({
  structure: {
    dimensions: state.board.dimensions,
    paths: state.board.paths
  },
  tileSize: state.board.options.tileSize
});

// @ts-ignore
// export default React.memo(Board, propsAreEqual);
export default connect(mapStateToProps)(Board);
