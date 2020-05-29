import React from "react";
import styled from "styled-components";
import { connect } from "react-redux";

import Card from "./Card";
import AssetUpload from "./AssetUpload";
import UploadedImage from "./UploadedImage";

import { uploadImages } from "../thunks/assets";
import { AppState, Image, Audio } from "../types";

interface Props {
  images: Image[];
  audio: Audio[];
  uploadImages: (files: FileList) => void;
}

const AssetLabel = styled.h2`
  font-size: 1.2rem;
  margin-bottom: 15px;
`;

const AssetBlock = styled.div`
  &:not(:last-of-type) {
    margin-bottom: 20px;
  }
`;

const AssetGrid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, 100px);
  grid-gap: 15px;
`;

const AssetManager: React.FC<Props> = (props) => {
  return (
    <Card title="Asset Manager" headerType="outside">
      <p>
        You can upload images and audio files to use as part of your game. Add
        them here and reference them through the <code>metadata</code> block.
      </p>

      <AssetBlock>
        <AssetLabel>Images</AssetLabel>
        <AssetGrid>
          {props.images.map((image) => (
            // @ts-ignore
            <UploadedImage key={image.id} image={image} />
          ))}
          <AssetUpload onFilesSelected={props.uploadImages} accept="image/*" />
        </AssetGrid>
      </AssetBlock>

      <AssetBlock>
        <AssetLabel>Music and Sounds</AssetLabel>
        <AssetUpload onFilesSelected={() => null} accept="audio/*" />
      </AssetBlock>
    </Card>
  );
};

const mapStateToProps = (state: AppState) => ({
  images: Object.values(state.images.byId),
  audio: Object.values(state.audio.byId)
});

const mapDispatchToProps = {
  uploadImages
};

export default connect(mapStateToProps, mapDispatchToProps)(AssetManager);
