import React from "react";
import styled from "styled-components";

import { CompileStatus } from "../types";
import CompilerStatus from "./CompilerStatus";

interface Props {
  connectedToEditor: boolean;
  lastCompiled: string;
  compileStatus: CompileStatus;
}

const StatusContainer = styled.div`
  display: flex;
  flex-flow: column;
  padding: 15px;
  overflow-y: scroll;
`;

const StatusBar: React.FC<Props> = () => {
  return (
    <StatusContainer>
      <CompilerStatus />
    </StatusContainer>
  );
};

export default StatusBar;
