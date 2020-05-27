// import React from "react";
import styled from "styled-components";
import { connect } from "react-redux";

import { AppState } from "../../types";

interface Props {
  tileSize: number;
}

const EmptyTile = styled.div`
  width: ${(props: Props) => props.tileSize + "px"};
  height: ${(props: Props) => props.tileSize + "px"};
`;

const mapStateToProps = (state: AppState) => ({
  tileSize: state.board.options.tileSize,
});

export default connect(mapStateToProps)(EmptyTile);
