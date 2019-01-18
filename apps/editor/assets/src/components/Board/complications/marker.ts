import { IFixedComplication, DisplayMode, complication } from "./complications";

import { MarkerPosition } from "../Marker";

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
