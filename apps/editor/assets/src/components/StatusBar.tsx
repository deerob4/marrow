import React from "react";
import styled from "styled-components";
import classnames from "classnames";

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

const StatusBar: React.FC<Props> = (props) => {
  const x = classnames("status-bar", {
    "status-bar--error": props.compileStatus.type === "error"
  });

  return (
    <StatusContainer>
      <CompilerStatus />
    </StatusContainer>
  );
};

export default StatusBar;
