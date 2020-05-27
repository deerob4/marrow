import React from "react";
import { useState } from "react";
import { connect } from "react-redux";
import classnames from "classnames";
import styled from "styled-components";

import { IDimensions, ICoord, IPath } from "../../types";

import cantor from "../../utils/cantor";
import PathLine from "./PathLine";
import Label from "./Label";
import { AppState, Traits } from "../../types";

interface Props {
  coord: ICoord;
  boardDimensions: IDimensions;
  showPathLines: boolean;
  showImages: boolean;
  tileSize: number;
  imageUrl?: string;
  traits: Traits;
  hash: number;
}

interface ITileStyle {
  tileSize: number;
  isHidden: boolean;
  image?: string;
  showImages: boolean;
  isHovering: boolean;
}

const Container = styled.div`
  width: ${(props: ITileStyle) => props.tileSize + "px"};
  height: ${(props: ITileStyle) => props.tileSize + "px"};
  border-color: ${(props: ITileStyle) =>
    props.isHidden ? "transparent" : "#d5d5d5"};
  background-image: ${(props: ITileStyle) =>
    props.image && props.showImages ? `url(${props.image})` : "none"};
  background-size: cover;
`;

const Tile: React.SFC<Props> = (props) => {
  const className = getTileClass(props.coord, props.boardDimensions);
  const pathLine: IPath | undefined = props.traits.pathLine && {
    ...props.traits.pathLine,
    // from: props.coord
  };
  const [isHovering, setIsHovering] = useState(false);

  function onHover() {
    setIsHovering(true);
  }

  function onLeave() {
    setIsHovering(false);
  }
  return (
    <Container
      className={className}
      isHovering={isHovering}
      isHidden={false}
      showImages={props.showImages}
      tileSize={props.tileSize}
      image={props.imageUrl}
      onMouseOver={onHover}
      onMouseLeave={onLeave}
    >
      {pathLine && props.showPathLines && <PathLine pathLine={pathLine} />}
      {isHovering && props.traits.labels && props.traits.labels.length
        ? props.traits.labels.map((label, i) => <Label key={i} {...label} />)
        : null}
    </Container>
  );
};

function getTileClass({ x, y }: ICoord, { width, height }: IDimensions) {
  return classnames("tile", {
    "tile--top-left": x === 1 && y === 1,
    "tile--top-right": x === width && y === 1,
    "tile--bottom-left": x === 1 && y === height,
    "tile--bottom-right": x === width && y === height,
    "tile--top-edge": y === 0,
    "tile--left-edge": x === 0,
    "tile--bottom-edge": y === height,
    "tile--right-edge": x === width,
  });
}

const mapStateToProps = (state: AppState, props: Props) => {
  const coordHash = cantor(props.coord.x - 1, props.coord.y - 1);

  return {
    ...state.board.options,
    boardDimensions: state.board.dimensions,
    traits: state.traits.get(coordHash) || {},
    imageUrl: getImageUrl(state, coordHash),
    hash: coordHash,
  };
};

function getImageUrl(state: AppState, coordHash: number) {
  const traits = state.traits.get(coordHash);

  if (traits && traits.image) {
    const imageId = state.images.byName[traits.image];
    const image = state.images.byId[imageId];
    return image ? image.url : undefined;
  } else {
    return undefined;
  }
}

export default connect(mapStateToProps)(Tile);
