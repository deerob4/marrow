import * as React from "react";
import styled from "styled-components";
import { connect } from "react-redux";
import Icon from "./Icon";
import AutoFocusInput from "./AutoFocusInput";
import { AppState, Image } from "../types";
import { deleteImage, renameImage } from "../thunks/assets";
import Spinner from "./Spinner";

interface Props {
  image: Image;
  deleteImage: (id: number) => void;
  renameImage: (id: number, name: string) => void;
  isDeleting: boolean;
}

interface State {
  isHovering: boolean;
  isRenaming: boolean;
  newName: string;
}

interface IStyleImageProps {
  src: string;
  isHovering: boolean;
}

const ImageContainer = styled.div`
  display: grid;
  grid-row-gap: 5px;
`;

const Image = styled.div`
  width: 100px;
  height: 100px;
  border-radius: 5px;
  cursor: pointer;
  transition: all 0.2s ease-in-out;
  background-image: url(${(props: IStyleImageProps) => props.src});
  background-size: cover;
  margin-bottom: 5px;

  position: ${(props: IStyleImageProps) =>
    props.isHovering ? "absolute" : "static"};
  filter: brightness(
    ${(props: IStyleImageProps) => (props.isHovering ? "50%" : "100%")}
  );
`;

const ImageIcon = styled.i`
  border: 1px solid #ffeeee;
  padding: 10px;
  border-radius: 5px;
  position: absolute;
  color: #ffeeee;
  cursor: pointer;
  margin: auto;

  &:hover {
    border-color: #ffffff;
    color: #ffffff;
  }

  transition: all 0.2s ease-in-out;
`;

const ImageName = styled.span`
  text-align: center;
  width: 100px;
  cursor: pointer;
`;

const IconRow = styled.div`
  width: 100%;
  margin-top: 32px;
`;

const DeleteIcon = styled(ImageIcon)`
  margin-left: 30px;
`;

class UploadedImage extends React.PureComponent<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = {
      isHovering: false,
      isRenaming: false,
      newName: this.props.image.name
    };
  }

  setHovering = () => {
    this.setState({ isHovering: true });
  };

  setNotHovering = () => {
    this.setState({ isHovering: false });
  };

  setRenaming = () => {
    this.setState({ isRenaming: true });
  };

  cancelRenaming = () => {
    this.setState({ isRenaming: false });
  };

  deleteImage = () => {
    this.props.deleteImage(this.props.image.id);
  };

  handleInput = (e: React.FormEvent<HTMLInputElement>) => {
    const newName = e.currentTarget.value;
    this.setState({ newName });
  };

  rename = () => {
    this.setState({ isRenaming: false });
    this.props.renameImage(this.props.image.id, this.state.newName);
  };

  renderImageName = () => {
    const element = this.state.isRenaming ? (
      <form onSubmit={this.rename}>
        <AutoFocusInput
          type="text"
          className="form-control mb-1"
          style={{ width: "100px" }}
          value={this.state.newName}
          onChange={this.handleInput}
        />

        <button
          type="button"
          style={{ width: "35px" }}
          className="btn btn-primary btn-sm mr-1"
          onClick={this.rename}>
          <Icon name="check" />
        </button>

        <button
          type="button"
          style={{ width: "35px" }}
          className="btn btn-secondary btn-sm"
          onClick={this.cancelRenaming}>
          <Icon name="times" />
        </button>
      </form>
    ) : (
      <ImageName onClick={this.setRenaming}>{this.props.image.name}</ImageName>
    );

    if (this.state.isHovering) {
      // Offset the move up caused by changing the image element to absolute.
      return <div style={{ marginTop: "73px" }}>{element}</div>;
    } else {
      return element;
    }
  };

  renderIcon = () => {
    if (this.props.isDeleting) {
      return <Spinner isSpinning={true} />;
    } else if (this.state.isHovering) {
      return (
        <IconRow>
          <DeleteIcon onClick={this.deleteImage} className="fas fa-trash" />
        </IconRow>
      );
    } else {
      return null;
    }
  };

  render() {
    return (
      <div>
        <ImageContainer
          onMouseEnter={this.setHovering}
          onMouseLeave={this.setNotHovering}>
          <Image
            isHovering={this.state.isHovering}
            src={this.props.image.url}
          />
          {this.renderIcon()}
          {/* {this.state.isHovering ? (
            <IconRow>
              <DeleteIcon onClick={this.deleteImage} className="fas fa-trash" />
            </IconRow>
          ) : null} */}
        </ImageContainer>
        {this.renderImageName()}
      </div>
    );
  }
}

const mapStateToProps = (state: AppState, props: Props) => ({
  isDeleting: state.deletingImages.includes(props.image.id)
});

const mapDispatchToProps = {
  deleteImage,
  renameImage
};

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(UploadedImage);
