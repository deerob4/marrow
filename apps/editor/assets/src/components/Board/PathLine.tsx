import React from "react";
import styled from "styled-components";
import { connect } from "react-redux";
import { ILineStyle, lineWidth } from "../Board";
import { PathDirection, IPath, MarkerPosition } from "../../types";

import Arrow from "./Arrow";
import Marker from "./Marker";
import { AppState } from "../../types";

const Line = styled.div`
  background-color: #212529;
  z-index: 100;
  position: absolute;
`;

const VerticalLine = styled(Line)`
  width: 2px;
  height: ${(props: ILineStyle) => lineWidth(props) - 8 + "px"};
`;

const HorizontalLine = styled(Line)`
  width: ${(props: ILineStyle) => lineWidth(props) - 7 + "px"};
  height: 2px;
`;

const UpLine = styled(VerticalLine)`
  transform: translateY(
    ${(props: ILineStyle) =>
      "-" + (lineWidth(props) - props.tileSize / 2 - 2) + "px"}
  );
  margin-left: ${(props: ILineStyle) => props.tileSize / 2 - 2 + "px"};
`;

const DownLine = styled(VerticalLine)`
  margin-left: ${(props: ILineStyle) => props.tileSize / 2 - 3 + "px"};
  margin-top: ${(props: ILineStyle) => props.tileSize / 2 + 2 + "px"};
`;

const LeftLine = styled(HorizontalLine)`
  transform: translate(${(props: ILineStyle) => "-" + lineWidth(props) + "px"});
  margin-top: ${(props: ILineStyle) => props.tileSize / 2 - 2 + "px"};
  margin-left: ${(props: ILineStyle) => props.tileSize / 2 + 2 + "px"};
`;

const RightLine = styled(HorizontalLine)`
  width: ${(props: ILineStyle) => lineWidth(props) - 7 + "px"};
  margin-left: ${(props: ILineStyle) => props.tileSize / 2 + 2 + "px"};
  margin-top: ${(props: ILineStyle) => props.tileSize / 2 - 2 + "px"};
`;

interface Props {
  pathLine: IPath;
  tileSize: number;
  showArrows: boolean;
}

interface IArrowProps {
  distance: number;
  direction: PathDirection;
  showArrows: boolean;
}

const PathLine: React.SFC<Props> = ({ pathLine, tileSize, showArrows }) => {
  const direction = pathDirection(pathLine);
  const distance = pathDistance(pathLine, direction);
  const arrowProps: IArrowProps = { direction, distance, showArrows };

  return (
    <>
      <Marker coord={pathLine.from} position={MarkerPosition.Start} />
      {renderLine(arrowProps, tileSize)}
    </>
  );
};

const renderLine = (arrowProps: IArrowProps, tileSize: number) => {
  const { distance, direction, showArrows } = arrowProps;

  switch (direction) {
    case PathDirection.Up:
      return (
        <UpLine distance={distance} tileSize={tileSize}>
          {showArrows && <Arrow {...arrowProps} />}
        </UpLine>
      );

    case PathDirection.Down:
      return (
        <DownLine distance={distance} tileSize={tileSize}>
          {showArrows && <Arrow {...arrowProps} />}
        </DownLine>
      );

    case PathDirection.Left:
      return (
        <LeftLine distance={distance} tileSize={tileSize}>
          {showArrows && <Arrow {...arrowProps} />}
        </LeftLine>
      );

    case PathDirection.Right:
      return (
        <RightLine distance={distance} tileSize={tileSize}>
          {showArrows && <Arrow {...arrowProps} />}
        </RightLine>
      );
  }
};

/**
 * Returns the number of tiles between the start and finish of `path`.
 * @param path The path to calculate the distance of.
 */
function pathDistance({ from, to }: IPath, direction: PathDirection): number {
  switch (direction) {
    case PathDirection.Left:
      return from.x - to.x;
    case PathDirection.Right:
      return to.x - from.x;
    case PathDirection.Up:
      return from.y - to.y;
    case PathDirection.Down:
      return to.y - from.y;
  }
}

/**
 * Returns the travel direction that the path is.
 *
 * For example, a path from `[0, 0]` to `[5, 0]` will return
 * `PathDirection.Right`, because it tells players to move in a
 * rightwards direction.
 *
 * @param path The path to check the direction of.
 */
function pathDirection({ from, to }: IPath): PathDirection {
  if (to.x > from.x) {
    return PathDirection.Right;
  } else if (from.x > to.x) {
    return PathDirection.Left;
  } else if (to.y > from.y) {
    return PathDirection.Down;
  } else if (from.y > to.y) {
    return PathDirection.Up;
  } else {
    throw new Error(`Invalid path: ${from}->${to}`);
  }
}

const mapStateToProps = (state: AppState) => ({
  tileSize: state.board.options.tileSize,
  showArrows: state.board.options.showArrows,
});

export default connect(mapStateToProps)(PathLine);
