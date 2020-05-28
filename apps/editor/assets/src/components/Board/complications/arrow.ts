import { IFixedComplication, DisplayMode, complication } from "./complications";
import { ICoord } from "../../../types";

interface IArrowComplication extends IFixedComplication {
  from: ICoord;
  to: ICoord;
}

function arrowComplication(from: ICoord, to: ICoord): IArrowComplication {
  return {
    type: complication("arrow"),
    displayMode: DisplayMode.Fixed,
    from,
    to
  };
}

export default arrowComplication;
