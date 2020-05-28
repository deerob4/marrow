import React from "react";
import styled from "styled-components";
import { connect } from "react-redux";

import FileUpload from "./FileUpload";
import Card from "./Card";
import { AppState } from "../types";
import { toggleIsPublic } from "../actions/GameActions";

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

const GameProperties: React.FC<Props> = (props) => {
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
          id="isPrivate"
          className="form-check-input"
          checked={props.isPublic || false}
          onChange={props.toggleIsPublic}
        />
        <label htmlFor="isPrivate" className="form-check-label">
          Game is public?
        </label>
      </div>
    </Card>
  );
};

const mapStateToProps = (state: AppState) => {
  const gameId = state.editingGame.metadataId;
  const game = state.gameMetadata.byId[gameId];

  return {
    isPublic: game.isPublic,
    headerImageUrl: game.coverUrl
  };
};

const mapDispatchToProps = {
  toggleIsPublic: toggleIsPublic.request
};

export default connect(mapStateToProps, mapDispatchToProps)(GameProperties);
