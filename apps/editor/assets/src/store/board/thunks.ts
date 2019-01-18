import { Socket } from "phoenix";
import { Dispatch } from "redux";
import { AppState } from "..";
import { resizeBoard as resizeBoardAction } from "./actions";

export function resizeBoard(newSize: number) {
  return (dispatch: Dispatch) => {
    window.localStorage.setItem("boardTileSize", newSize.toString());
    dispatch(resizeBoardAction(newSize));
  };
}
