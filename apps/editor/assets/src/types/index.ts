import { ActionType } from "typesafe-actions";
import { RouterState, LocationChangeAction } from "connected-react-router";
import { Map } from "immutable";

import * as authActions from "../actions/AuthActions";
import * as gameActions from "../actions/GameActions";
import * as assetActions from "../actions/AssetActions";
import * as editorActions from "../actions/EditorActions";
import * as boardActions from "../actions/BoardActions";
import * as socketActions from "../actions/SocketActions";

export type ById<T> = { [id: number]: T };

export type DomainResource<T> = {
  byId: ById<T>;
  allIds: number[];
};

/**
 * The fields required to signup to the application.
 */
export type SignupFields = {
  name: string;
  email: string;
  password: string;
};

/**
 * The fields required to login to the application.
 */
export type LoginCredentials = {
  email: string;
  password: string;
};

/**
 * Payload received when successfully signed in.
 */
export type AfterLogin = {
  user: User;
  games: GameMetadata[];
  token: string;
};

/**
 * Basic information about a game that can be used to identify
 * it without having to fetch the entire game source code and
 * structure.
 */
export type GameMetadata = {
  id: number;
  title: string;
  isPrivate: boolean;
  coverUrl: string;
};

/**
 * An actionable event in the game that introduces a notion of
 * interaction.
 */
export type Card = {
  title: string;
  stack: string;
  body: string;
  choices: string[];
};

/**
 * Defines an individual point on a 2D cartesian grid.
 */
export type Coord = {
  x: number;
  y: number;
};

/**
 * A horizontal or vertical line from one `Coord` to another.
 */
export type Path = {
  from: Coord;
  to: Coord;
};

/**
 * The width and height of a 2D board.
 */
export type Dimensions = {
  width: number;
  height: number;
};

/**
 * Available options for the board.
 */
export type BoardOptions = {
  tileSize: number;
  showPathLines: boolean;
  showUnusedTiles: boolean;
  showArrows: boolean;
  showImages: boolean;
};

/**
 * A 2D board on which the games are played out.
 */
export type Board = {
  dimensions: Dimensions;
  paths: Path[];
  options: BoardOptions;
};

/**
 * A label associated with a tile that provides additional
 * context to the board.
 */
export type Label = {
  title: string;
  body: string;
};

/**
 * The currently logged in user.
 */
export type User = {
  id: string;
  name: string;
  email: string;
};

/**
 * The game that is currently loaded into the editor and being
 * modified. This structure contains more information about the
 * game than the `GameMetadata` type.
 */
export type EditingGame = {
  metadataId: number;
  source: string;
  compileStatus: CompileStatus;
};

/**
 * The payload received upon successfull connection to an editor
 * channel.
 */
export type EditorConnect = {
  labels: Label[];
  images: Image[];
  audio: Audio[];
  board: Board;
  cards: Card[];
  imageTraits: Trait<ImageTrait>[];
  labelTraits: Trait<string>[];
  editingGame: EditingGame;
  isCompiled: boolean;
};

export type Trait<T> = {
  coord: Coord;
  value: T;
};

export type ImageTrait = string

/**
 * The payload received upon successful recompilation of the
 * game.
 */
export type CompilationSuccess = {
  labels: Trait<Label>[];
  audio: Trait<Audio>[];
  cards: Card[];
  images: Trait<ImageTrait>[];
  board: Board;
  editingGame: EditingGame;
};

/**
 * The position on the board that a marker trait denotes.
 */
export enum MarkerPosition {
  Start,
  EnRoute,
  Finish
}

/**
 * Denotes that a tile is the starting point for a set of game
 * `roles`.
 */
export type StartPoint = {
  roles: string[];
};

/**
 * The constant set of traits associated with each coordinate.
 */
export type Traits = {
  image?: string;
  labels?: Label[];
  marker?: MarkerPosition;
  pathLine?: Path;
};

/**
 * The current status of the compilation attempt.
 */
export type CompileStatus = OkStatus | CompilingStatus | ErrorStatus;

type OkStatus = { type: "ok" };
type CompilingStatus = { type: "compiling" };
type ErrorStatus = { type: "error"; error: string };

/**
 * The different types of assets that can be in the game.
 */
export type AssetType = "image" | "audio";

/**
 * An image that can be displayed on the game board.
 */
export type Image = Asset<"image">;

/**
 * An audio file that can be played at specified points in the
 * game.
 */
export type Audio = Asset<"audio">;

/**
 * A generic asset of type `T`.
 */
export type Asset<T extends AssetType> = {
  id: number;
  name: string;
  url: string;
  type: T;
};

/**
 * Represents an asset that's just been selected from the user's
 * drive. This won't yet have anything like an id and the url won't
 * be final, so it needs to be different.
 */
export type UploadingAssets = { [id: string]: File };

/**
 * A message to rename an asset.
 */
export type RenameAsset<T extends AssetType> = {
  id: number;
  name: string;
  type: T;
};

/**
 * The current status of the authentication page.
 */
export type AuthStatus = "idle" | "loggingIn" | "signingUp";

export type Action =
  | ActionType<typeof authActions>
  | ActionType<typeof gameActions>
  | ActionType<typeof assetActions>
  | ActionType<typeof editorActions>
  | ActionType<typeof boardActions>
  | ActionType<typeof socketActions>
  | LocationChangeAction;

export type GameMetadataState = DomainResource<GameMetadata>;
export type ImagesState = DomainResource<Image> & {byName: {[name: string]: number}}
export type AudioState = DomainResource<Audio>;
export type LabelsState = DomainResource<Label>;
export type CardsState = Card[];
export type BoardState = Board;

export type AuthState = {
  status: AuthStatus;
  error: string | null;
  loggedIn: boolean;
  token: string;
  isCheckingSession: boolean;
};

export type SocketState = {
  socketConnected: boolean;
  editorConnected: boolean;
};

export type TraitMap = Map<number, Traits>;

export type AppState = {
  images: ImagesState;
  audio: AudioState;
  board: BoardState;
  user: User;
  cards: CardsState;
  gameMetadata: GameMetadataState;
  editingGame: EditingGame;
  auth: AuthState;
  router: RouterState;
  socket: SocketState;
  traits: TraitMap;
  deletingImages: number[]
};
