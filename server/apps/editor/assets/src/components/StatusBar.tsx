import * as React from "react";
import styled from "styled-components";

import { CompileStatus } from "../store/games/types";
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

const StatusBar: React.SFC<Props> = props => {
  let x = classnames("status-bar", {
    "status-bar--error": props.compileStatus.type === "error"
  });

  return (
    <StatusContainer>
      <CompilerStatus />
    </StatusContainer>
  );
};
