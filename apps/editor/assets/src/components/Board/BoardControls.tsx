import React from "react";
import { connect } from "react-redux";

import {
  editTileSize,
  toggleShowPathLines,
  toggleShowArrows,
  toggleShowUnusedTiles,
  toggleShowImages
} from "../../actions/BoardActions";
import { AppState } from "../../types";

interface Props {
  tileSize: number;
  resizeBoard: (newSize: number) => void;

  showPathLines: boolean;
  toggleShowPathLines: typeof toggleShowPathLines;

  showArrows: boolean;
  toggleShowArrows: typeof toggleShowArrows;

  showUnusedTiles: boolean;
  toggleShowUnusedTiles: typeof toggleShowUnusedTiles;

  showImages: boolean;
  toggleShowImages: typeof toggleShowImages;
}

const BoardControls: React.FC<Props> = (props) => {
  return (
    <div className="board-controls">
      <div className="form-group">
        <label htmlFor="tileSize">Tile Size</label>
        <input
          id="tileSize"
          type="range"
          min={25}
          max={100}
          className="form-control-range"
          value={props.tileSize}
          onChange={(e) => props.resizeBoard(parseInt(e.target.value, 10))}
        />
      </div>

      <div className="form-check">
        <input
          id="showPathLines"
          type="checkbox"
          className="form-check-input"
          checked={props.showPathLines}
          onChange={props.toggleShowPathLines}
        />
        <label className="form-check-label" htmlFor="showPathLines">
          Show path lines?
        </label>
      </div>

      <div className="form-check">
        <input
          id="showArrows"
          type="checkbox"
          disabled={!props.showPathLines}
          className="form-check-input"
          checked={props.showArrows}
          onChange={props.toggleShowArrows}
        />
        <label className="form-check-label" htmlFor="showArrows">
          Show arrows?
        </label>
      </div>

      <div className="form-check">
        <input
          id="showUnusedTiles"
          type="checkbox"
          className="form-check-input"
          checked={props.showUnusedTiles}
          onChange={props.toggleShowUnusedTiles}
        />
        <label className="form-check-label" htmlFor="showUnusedTiles">
          Show unused tiles?
        </label>
      </div>

      <div className="form-check">
        <input
          id="showImages"
          type="checkbox"
          className="form-check-input"
          checked={props.showImages}
          onChange={props.toggleShowImages}
        />
        <label className="form-check-label" htmlFor="showImages">
          Show images?
        </label>
      </div>
    </div>
  );
};

const mapStateToProps = (state: AppState) => ({
  ...state.board.options
});

const mapDispatchToProps = {
  resizeBoard: editTileSize,
  toggleShowArrows,
  toggleShowPathLines,
  toggleShowUnusedTiles,
  toggleShowImages
};

export default connect(mapStateToProps, mapDispatchToProps)(BoardControls);
