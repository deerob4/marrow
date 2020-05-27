import { IFixedComplication, DisplayMode, complication } from "./complications";

import { MarkerPosition } from "../../../types";

interface IMarkerComplication extends IFixedComplication {
  position: MarkerPosition;
}

function markerComplication(position: MarkerPosition): IMarkerComplication {
  return {
    type: complication("marker"),
    displayMode: DisplayMode.Fixed,
    position
  };
}

export default markerComplication;
