import * as React from "react";
import Icon from "./Icon";
import styled from "styled-components";

interface Props {
  name: string;
  icon: string;
  isActive: boolean;
  onClick: () => void;
}

const ActionButtonContainer = styled.div`
  font-size: 22px;
  color: ${(p: any) => (p.isActive ? "#fff" : "#b4caff")};
  cursor: pointer;
  text-align: center;
  margin-bottom: 20px;
  &:hover {
    color: #fff;
  }
  &:last-of-type {
    margin-bottom: 10px;
  }
`;

const ActionButton: React.SFC<Props> = props => {
  return (
    // @ts-ignore
    <ActionButtonContainer onClick={props.onClick} isActive={props.isActive}>
      <Icon name={props.icon} />
    </ActionButtonContainer>
  );
};

export default ActionButton;
