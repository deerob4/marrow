import { MarkerPosition } from "../Marker";
import { ICoord } from "../../../store/board/types";

// A complication is anything that appears on the board.

export enum DisplayMode {
  Fixed,
  Hover
}

type Complication = {
  name: string;
};

export interface IComplication {
  type: Complication;
  displayMode: DisplayMode;
}

export interface IHoverComplication extends IComplication {
  displayMode: DisplayMode.Hover;
}

export interface IFixedComplication extends IComplication {
  displayMode: DisplayMode.Fixed;
}

export const complication = (name: string): Complication => ({ name });
