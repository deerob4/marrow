import {
  IFixedComplication,
  DisplayMode,
  IComplication,
  complication
} from "./complications";
import { ICoord } from "../../../store/board/types";
import cantor from "../../../utils/cantor";

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
