import { IFixedComplication, DisplayMode, complication } from "./complications";

interface IImageComplication extends IFixedComplication {
  title: string;
  imageUrl: string;
}

function imageComplication(
  title: string,
  imageUrl: string
): IImageComplication {
  return {
    type: complication("image"),
    displayMode: DisplayMode.Fixed,
    title,
    imageUrl
  };
}

export default imageComplication;
