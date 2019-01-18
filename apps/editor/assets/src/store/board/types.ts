import { Map } from "immutable";

export enum BoardActionType {
  RESIZE_BOARD = "@@board/RESIZE_BOARD",
  UPDATE_BOARD_STRUCTURE = "@@board/UPDATE_BOARD_STRUCTURE",
  TOGGLE_SHOW_BOARD_PATH_LINES = "@@board/TOGGLE_SHOW_BOARD_PATH_LINES",
  TOGGLE_SHOW_BOARD_ARROWS = "@@board/TOGGLE_SHOW_BOARD_ARROWS",
  TOGGLE_SHOW_UNUSED_TILES = "@@board/TOGGLE_SHOW_UNUSED_TILES",
  TOGGLE_SHOW_IMAGES = "@@board/TOGGLE_SHOW_IMAGES",
}

export enum Axis {
  XAxis,
  YAxis
}

/**
 * The direction in which a path line may point.
 */
export enum PathDirection {
  Up = "up",
  Down = "down",
  Left = "left",
  Right = "right"
}

/**
 * A line in a certain direction that is `distance` number of
 * tiles across the board.
 */
export interface IPathLine {
  direction: PathDirection;
  distance: number;
}

/**
 * The width and height of the game board.
 */
export interface IDimensions {
  width: number;
  height: number;
}

/**
 * A single point on a 2D Cartesian grid.
 */
export interface ICoord {
  x: number;
  y: number;
}

/**
 * A vertical or horizontal path line between two coordinates.
 */
export interface IPath {
  from: ICoord;
  to: ICoord;
}

export interface IBoardStructure {
  dimensions: IDimensions;
  paths: IPath[];
}

/**
 * A mapping between Cantor-paired board coordinates and image
 * names.
 */
export interface IBoardImage {
  [tilePair: number]: string;
}

/**
 * The different varieties of traits that can appear on the board.
 */
export enum TraitType {
  Image,
  Label,
  Marker,
  Arrow,
  Trigger,
  StartPoint
}

/**
 * How the trait is displayed on the board.
 */
export enum DisplayMode {
  /**
   * Only appears when the mouse is hovered over the tile.
   */
  Hover,

  /**
   * Always shown.
   */
  Fixed
}

/**
 * The position on the board that a marker trait denotes.
 */
export enum MarkerPosition {
  Start,
  EnRoute,
  Finish
}

/**
 * Trait for displaying an arbitrary text label on hover.
 */
export interface ILabelTrait {
  title: string;
  body: string;
}

/**
 * Trait for setting a tile's background image.
 */
export interface IImageTrait {
  imageUrl: string;
}

/**
 * Trait that associates a tile with a role's starting point.
 */
export interface IStartPointTrait {
  role: string;
}

/**
 * Trait that indicates a particular event happens on this tile
 * at the end of the turn.
 */
export interface ITriggerTrait {
  event: string;
  desc: string;
}

/**
 * Trait that denotes a certain point on the board's path.
 *
 * They are placed at the start of the path, the end, and
 * wherever a new angle is formed.
 */
export interface IMarkerTrait {
  position: MarkerPosition;
}

/**
 * Trait that visualises a section of the path.
 */
export interface IPathLineTrait {
  to: ICoord;
}

/**
 * Set of options relating to how the board is displayed.
 */
export interface IBoardOptions {
  tileSize: number;
  showArrows: boolean;
  showUnusedTiles: boolean;
  showPathLines: boolean;
  showImages: boolean;
}

/**
 * A fixed structure defining the individual traits that a tile
 * can have.
 */
export interface Traits {
  image?: IImageTrait;
  labels?: ILabelTrait[];
  startPoints?: IStartPointTrait[];
  triggers?: ITriggerTrait[];
  pathLine?: IPathLineTrait;
  marker?: IMarkerTrait;
}

export interface BoardState {
  structure: IBoardStructure | null;
  options: IBoardOptions;
  boardImages: IBoardImage;
  // mapping between Cantor-paired board coordinates and additional traits.
  readonly traits: Map<number, Traits>;
}
