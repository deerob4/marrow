import React from "react";
import styled from "styled-components";
import { Axis } from "../../types";

const CoordContainer = styled.div`
  font-weight: bold;
  margin: auto;
`;

interface Props {
  value: number;
}

const Coordinate: React.FC<Props> = ({ value }) => {
  return <CoordContainer>{value}</CoordContainer>;
};

export default Coordinate;
