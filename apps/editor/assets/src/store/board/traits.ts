import {
  IImageTrait,
  ILabelTrait,
  IStartPointTrait,
  ITriggerTrait,
  IPathLineTrait,
  IMarkerTrait,
  ICoord,
  PathDirection,
  MarkerPosition
} from "./types";

/**
 * Returns a new image trait property.
 * @param imageUrl The url of the image to show.
 */
export function imageTrait(imageUrl: string): IImageTrait {
  return { imageUrl };
}

/**
 * Returns a new label trait.
 * @param title The title of the label.
 * @param body The label's body text.
 */
export function labelTrait(title: string, body: string): ILabelTrait {
  return { title, body };
}

/**
 * Returns a new trigger trait.
 * @param event The event that takes place on the tile.
 * @param desc A description of the event.
 */
export function triggerTrait(event: string, desc: string): ITriggerTrait {
  return { event, desc };
}

/**
 * Returns a new start point trait.
 * @param role The role being placed on the tile.
 */
export function startPointTrait(role: string): IStartPointTrait {
  return { role };
}

/**
 * Returns a new marker trait.
 * @param position The position the marker is placed at.
 */
export function markerTrail(position: MarkerPosition): IMarkerTrait {
  return { position };
}

/**
 * Returns a new arrow trait.
 * @param from The coordinates of the arrow's origin.
 * @param to The coordinates of the arrow's destination.
 */
export function pathLineTrait(to: ICoord): IPathLineTrait {
  return { to };
}
