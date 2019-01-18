import * as React from "react";
import { connect } from "react-redux";
import styled from "styled-components";
import * as ReactMarkdown from "react-markdown";
import { AppState } from "../types";
import { compose } from "ramda";

interface Props {
  isOkay: boolean;
  isCompiling: boolean;
  isError: boolean;
  errorMessage: string | null;
}

const StatusContainer = styled.div`
  display: flex;
  flex-flow: column;
  padding: 15px;
  overflow-y: scroll;
`;

const StatusName = styled.h3``;

const CompileError = styled.div`
  margin-bottom: 0;
  font-size: 18px;
`;


function capitaliseFirstLetter(string: string) {
  const first = string[0];
  const rest = string.slice(1, string.length);
  
  return first.toUpperCase() + rest;
}

function addFullStop(string: string) {
  if (string.endsWith("?") || string.endsWith(".")) {
    return string;
  } else {
    return string + ".";
  }
}

const formatError = compose(capitaliseFirstLetter, addFullStop);

const CompilerStatus: React.SFC<Props> = props => {
  if (props.isOkay) {
    return (
      <StatusContainer>
        <StatusName>No Errors</StatusName>
      </StatusContainer>
    );
  }

  if (props.isCompiling) {
    return (
      <StatusContainer>
        <StatusName>Compiling...</StatusName>
      </StatusContainer>
    );
  }

  if (props.isError && props.errorMessage) {
    let errorMessage = formatError(props.errorMessage);

    return (
      <StatusContainer>
        <StatusName>Compile Error</StatusName>
        <CompileError>
          <ReactMarkdown source={errorMessage} />
        </CompileError>
      </StatusContainer>
    );
  }

  // Satisfy the compiler.
  return null;
};

const mapStateToProps = (state: AppState) => {
  const compileStatus = state.editingGame.compileStatus;

  return {
    isOkay: compileStatus.type === "ok",
    isCompiling: compileStatus.type === "compiling",
    isError: compileStatus.type === "error",
    errorMessage: compileStatus.type === "error" ? compileStatus.error : null
  };
};

export default connect(mapStateToProps)(CompilerStatus);
