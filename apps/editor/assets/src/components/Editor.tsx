import React from "react";
import { connect } from "react-redux";
import styled from "styled-components";
import { RouteComponentProps } from "react-router";
import { merge } from "ramda";

import {
  editGameSource,
  connectToEditor,
  leaveEditor,
  recompile,
} from "../actions/EditorActions";

import { AppState, EditingGame, GameMetadata } from "../types";

import CodeEditor from "./CodeEditor";
import LanguageReference from "./LanguageReference";
import GameProperties from "./GameProperties";
import AssetManager from "./AssetManager";
import BoardViewer from "./BoardViewer";
import ActionBar from "./ActionBar";
import CompilerStatus from "./CompilerStatus";
import { push } from "connected-react-router";

enum Panel {
  LanguageReference,
  GameProperties,
  AssetManager,
  BoardViewer,
  Cards,
}

interface Props extends RouteComponentProps {
  game: EditingGame & GameMetadata;
  editGameSource: typeof editGameSource;
  recompile: () => void;
  connectToEditor: (id: number) => void;
  leaveEditor: () => void;
  push: (location: string) => void;
}

interface State {
  currentPanel: Panel;
}

const EditorGrid = styled.div`
  display: grid;
  height: 100%;
  grid-template-columns: 55px 2fr 1fr;
  grid-template-rows: 100% 80% 10% 100%;
  overflow-y: hidden;

  @media (max-width: 1500px) {
    grid-template-columns: 55px minmax(600px, 3fr) 2fr;
  }
`;

const InnerGrid = styled.div`
  display: grid;
  grid-template-rows: 85% minmax(60px, 15%);
`;

class Editor extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props);

    this.state = {
      currentPanel: Panel.LanguageReference,
    };
  }

  componentDidMount() {
    const previouslySet = localStorage.getItem("editorPanel");

    if (previouslySet) {
      this.setPanel(parseInt(previouslySet, 10));
    }
    this.props.connectToEditor(this.props.game.id);
    this.setTitle();
  }

  componentDidUpdate() {
    this.setTitle();
  }

  setTitle() {
    document.title = `Editing ${this.props.game.title} - Marrow`;
  }

  componentWillUnmount() {
    this.props.leaveEditor();
  }

  setPanel = (panel: Panel) => {
    this.setState({ currentPanel: panel });
    window.localStorage.setItem("editorPanel", panel.toString());
  };

  renderPanel = () => {
    switch (this.state.currentPanel) {
      case Panel.LanguageReference:
        return <LanguageReference />;
      case Panel.GameProperties:
        return <GameProperties updateProperties={console.log} />;
      case Panel.AssetManager:
        return <AssetManager />;
      case Panel.BoardViewer:
        return <BoardViewer />;
    }
  };

  leaveEditor = () => {
    this.props.push("/games");
  };

  render() {
    const panel = this.state.currentPanel;

    return (
      <>
        <EditorGrid>
          <ActionBar
            topActions={[
              {
                name: "recompile",
                icon: "sync",
                onClick: this.props.recompile,
                isActive: false,
              },
              {
                name: "languageReference",
                icon: "question-circle",
                onClick: () => this.setPanel(Panel.LanguageReference),
                isActive: panel === Panel.LanguageReference,
              },
              {
                name: "boardViewer",
                icon: "vector-square",
                onClick: () => this.setPanel(Panel.BoardViewer),
                isActive: panel === Panel.BoardViewer,
              },
              {
                name: "cards",
                icon: "route ",
                onClick: () => this.setPanel(Panel.Cards),
                isActive: panel === Panel.Cards,
              },
              {
                name: "assets",
                icon: "images",
                onClick: () => this.setPanel(Panel.AssetManager),
                isActive: panel === Panel.AssetManager,
              },
              {
                name: "settings",
                icon: "cog",
                onClick: () => this.setPanel(Panel.GameProperties),
                isActive: panel === Panel.GameProperties,
              },
            ]}
            bottomActions={[
              {
                name: "games",
                icon: "home",
                onClick: this.leaveEditor,
                isActive: false,
              },
            ]}
          />
          <InnerGrid>
            <CodeEditor
              value={this.props.game.source}
              onChange={(newSource) => {
                this.props.editGameSource(this.props.game.id, newSource);
              }}
            />
            <CompilerStatus />
          </InnerGrid>
          {this.renderPanel()}
        </EditorGrid>
      </>
    );
  }
}

const mapDispatchToProps = {
  editGameSource,
  connectToEditor: connectToEditor.request,
  recompile: recompile.request,
  leaveEditor,
  push,
};

const mapStateToProps = (state: AppState) => {
  const editingGame = state.editingGame;
  const gameMetadata = state.gameMetadata.byId[editingGame.metadataId];

  return {
    game: merge(editingGame, gameMetadata),
  };
};

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(Editor);
