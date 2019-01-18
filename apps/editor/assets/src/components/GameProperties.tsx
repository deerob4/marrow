import * as React from "react";
import styled from "styled-components";
import { connect } from "react-redux";

import { toggleIsPublic } from "../store/games/thunks";

import FileUpload from "./FileUpload";
import Card from "./Card";
import { AppState } from "../types";

const HeaderImage = styled.div`
  width: 100%;
  height: 250px;
  border-radius: 5px;
  background-image: url(${(props: { src: string }) => props.src});
  background-size: cover;
  cursor: pointer;
`;

interface Props {
  updateProperties: () => void;
  isPublic: boolean;
  headerImageUrl: string;
  toggleIsPublic: () => void;
}

const GameProperties: React.SFC<Props> = props => {
  console.log(props);
  return (
    <Card title="Properties" headerType="outside">
      <div className="form-group">
        <label>Header Image</label>
        <FileUpload onFilesSelected={console.log}>
          {(handleFileSelect, isUploading) => (
            <HeaderImage
              src={props.headerImageUrl}
              onClick={handleFileSelect}
            />
          )}
        </FileUpload>
      </div>

      <div className="form-group form-check">
        <input
          type="checkbox"
          id="isPublic"
          className="form-check-input"
          checked={props.isPublic || false}
          onChange={props.toggleIsPublic}
        />
        <label htmlFor="isPublic" className="form-check-label">
          Public?
        </label>
      </div>
    </Card>
  );
};

const mapStateToProps = (state: AppState) => {
  const gameId = state.editingGame.metadataId;
  const game = state.gameMetadata.byId[gameId];

  return {
    isPublic: !game.isPrivate,
    headerImageUrl: game.coverUrl
  };
};

const mapDispatchToProps = {
  toggleIsPublic
};

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(GameProperties);
