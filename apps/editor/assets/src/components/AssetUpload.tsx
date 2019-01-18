import * as React from "react";
import styled from "styled-components";
import FileUpload from "./FileUpload";

interface Props {
  onFilesSelected: (files: FileList) => void;
  accept?: string;
}

const Upload = styled.div`
  width: 100px;
  height: 100px;
  border: 1px solid #d5d5d5;
  border-radius: 5px;
  text-align: center;
  font-size: 55px;
  color: #d5d5d5;
  transition: all 0.1s ease-in-out;

  &:hover {
    border-color: #6161ff;
    border: 2px solid #6161ff;
    color: #6161ff;
    cursor: pointer;
  }
`;

const AssetUpload: React.SFC<Props> = ({ onFilesSelected, accept }) => {
  return (
    <FileUpload onFilesSelected={onFilesSelected} accept={accept}>
      {(handleFileSelect, isUploading) => (
        <Upload onClick={handleFileSelect}>
          {!isUploading ? "+" : <i className="fa-spin">+</i>}
        </Upload>
      )}
    </FileUpload>
  );
};

export default AssetUpload;
