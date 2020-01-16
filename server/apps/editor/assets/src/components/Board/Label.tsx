import * as React from "react";
import styled from "styled-components";

interface Props {
  title: string;
  body: string;
}

const LabelContainer = styled.div`
  min-width: 360px;
  padding: 10px;
  border: 1px solid;
  z-index: 0;
  background-color: #bfbfe1;
  box-shadow: 2px 2px 0px 0px #5e609e;
  margin-bottom: 10px;
`;

const Title = styled.h1`
  font-size: 20px;
  font-family: europa, sans-serif;
  font-weight: bold;
  text-align: left;
`;

const Body = styled.p`
  font-size: 15px;
  font-family: europa, sans-serif;
  text-align: left;
  margin-bottom: 0;
`;

const Label: React.SFC<Props> = ({ title, body }) => {
  return (
    <LabelContainer>
      <Title>{title}</Title>
      <Body>{body}</Body>
    </LabelContainer>
  );
};

export default Label;
