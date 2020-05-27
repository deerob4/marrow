import React from "react";
import ActionButton from "./ActionButton";
import styled from "styled-components";

interface IActionButton {
  name: string;
  icon: string;
  isActive: boolean;
  onClick: () => void;
}

interface Props {
  topActions: IActionButton[];
  bottomActions: IActionButton[];
}

const ActionBarContainer = styled.div`
  height: 100%;
  background-color: #6161e4;
  display: flex;
  flex-direction: column;
  align-items: center;
  padding-top: 10px;
  justify-content: space-between;
`;

const TopActions = styled.div``;

const BottomActions = styled.div``;

const ActionBar: React.SFC<Props> = ({ topActions, bottomActions }) => {
  function renderActionButton(action: IActionButton) {
    return <ActionButton key={action.name} {...action} />;
  }

  return (
    <ActionBarContainer>
      <TopActions>{topActions.map(renderActionButton)}</TopActions>
      <BottomActions>{bottomActions.map(renderActionButton)}</BottomActions>
    </ActionBarContainer>
  );
};

export default ActionBar;
