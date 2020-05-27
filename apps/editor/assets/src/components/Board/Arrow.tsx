import React from "react";
import styled from "styled-components";
import { PathDirection } from "../../types";
import { ILineStyle, lineWidth } from "../Board";
import { connect } from "react-redux";
import { AppState } from "../../types";

const ArrowParent = styled.div`
  transform: scale(1.2);
  color: #212529;
  width: 10px;
  cursor: pointer;
`;

const UpArrow = styled(ArrowParent)`
  margin-left: -7px;
  margin-top: ${(props: ILineStyle) => lineWidth(props) / 2 - 17 + "px"};
`;

const DownArrow = styled(ArrowParent)`
  transform: rotate(180deg) scale(1.2);
  margin-left: -3px;
  margin-top: ${(props: ILineStyle) => lineWidth(props) / 2 - 12 + "px"};
`;

const LeftArrow = styled(ArrowParent)`
  transform: rotate(270deg) scale(1.2);
  margin-top: -8px;
  margin-left: ${(props: ILineStyle) => lineWidth(props) / 2 - 4 + "px"};
`;

const RightArrow = styled(ArrowParent)`
  transform: rotate(90deg) scale(1.2);
  margin-top: -14px;
  margin-left: ${(props: ILineStyle) => lineWidth(props) / 2 - 12 + "px"};
`;

interface Props {
  direction: PathDirection;
  distance: number;
  tileSize: number;
}

const ARROW_GLYPH = "▲";

const Arrow: React.SFC<Props> = (props) => {
  switch (props.direction) {
    case PathDirection.Up:
      return <UpArrow {...props}>{ARROW_GLYPH}</UpArrow>;

    case PathDirection.Down:
      return <DownArrow {...props}>{ARROW_GLYPH}</DownArrow>;

    case PathDirection.Left:
      return <LeftArrow {...props}>{ARROW_GLYPH}</LeftArrow>;

    case PathDirection.Right:
      return <RightArrow {...props}>{ARROW_GLYPH}</RightArrow>;
  }
};

const mapStateToProps = (state: AppState) => ({
  tileSize: state.board.options.tileSize,
});

export default connect(mapStateToProps)(Arrow);
