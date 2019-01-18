import * as React from "react";

interface Props {
  onFilesSelected: (files: FileList) => void;
  accept?: string;
  children: (
    openFileDialog: (e: React.MouseEvent) => void,
    isUploading: boolean
  ) => React.ReactNode;
}

interface State {
  isUploading: boolean;
}

class FileUpload extends React.Component<Props, State> {
  fileSelector: HTMLInputElement | null;

  constructor(props: Props) {
    super(props);
    this.fileSelector = null;
    this.state = { isUploading: false };
  }

  componentDidMount() {
    this.fileSelector = this.buildFileSelector();
    this.fileSelector.addEventListener("change", this.onFileSelect);
  }

  componentWillUnmount() {
    if (!this.fileSelector) return null;
    this.fileSelector.removeEventListener("change", this.onFileSelect);
  }

  openFileDialog = (e: React.MouseEvent) => {
    e.preventDefault();

    if (!this.fileSelector) return null;

    this.fileSelector.click();
  };

  onFileSelect = () => {
    const files = this.fileSelector!.files!;
    this.props.onFilesSelected(files);
  };

  render() {
    return this.props.children(this.openFileDialog, this.state.isUploading);
  }

  private buildFileSelector() {
    const fileSelector = document.createElement("input");
    fileSelector.setAttribute("type", "file");
    fileSelector.setAttribute("multiple", "multiple");

    if (this.props.accept)
      fileSelector.setAttribute("accept", this.props.accept);

    return fileSelector;
  }
}

export default FileUpload;
