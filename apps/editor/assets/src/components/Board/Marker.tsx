import * as React from "react";
import styled from "styled-components";
import { MarkerPosition, ICoord } from "../../store/board/types";
import { compose, eqProps, and, cond } from "ramda";
import { connect } from "react-redux";
import { AppState } from "../../types";

interface Props {
  coord: ICoord;
  position: MarkerPosition;
}

const Container = styled.div`
  width: 10px;
  height: 10px;
  border-radius: 50%;
  border: 2px solid #212529;
  margin: auto;
`;

const StartMarker = styled(Container)`
  background-color: pink;
`;

const EnRouteMarker = styled(Container)`
  background-color: none;
`;

const FinishMarker = styled(Container)`
  background-color: green;
`;

/**
 * Denotes a specific point on the board.
 */
const Marker: React.SFC<Props> = ({ position }) => {
  switch (position) {
    case MarkerPosition.Start:
      return <StartMarker />;

    case MarkerPosition.EnRoute:
      return <EnRouteMarker />;

    case MarkerPosition.Finish:
      return <FinishMarker />;
  }
};

function mapStateToProps(state: AppState, props: Props) {
  const firstPath = state.board.paths.length ? state.board.paths[0] : null;

  const position =
    firstPath && sameCoord(firstPath.from, props.coord)
      ? MarkerPosition.Start
      : MarkerPosition.EnRoute;

  return { position };
}

const sameCoord = and(eqProps("x"), eqProps("y"));

export default connect(mapStateToProps)(Marker);
