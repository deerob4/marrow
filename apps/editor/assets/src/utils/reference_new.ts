import { Types, MarrowType, typeToString, formatFunction } from "./marrow_type";

const {
  int,
  string,
  bool,
  tile,
  atom,
  any,
  list,
  role,
  identifier,
  pair,
  or
} = Types;

export enum Category {
  Game = "game",
  Variables = "variables",
  Players = "players",
  Logic = "logic",
  Board = "board",
  Other = "other",
  Communication = "communication"
}

export enum RefType {
  Block = "Blocks",
  Function = "Functions",
  Command = "Commands",
  Property = "Properties",
  GlobalVar = "Global Variables",
  Callback = "Callbacks"
}

export interface RefInfo {
  name: string;
  details: string;
  category: Category;
}

export type AllowedInside =
  | { kind: "logic" }
  | { kind: "specific"; block: string };

export interface Block {
  kind: RefType.Block;
  required: boolean;
}

export interface Function {
  kind: RefType.Function;
  args: MarrowType[];
  returnType: MarrowType;
  example?: string;
}

export interface Command {
  kind: RefType.Command;
  args: MarrowType[];
  allowedInside: AllowedInside;
}

export interface Property {
  kind: RefType.Property;
  type: MarrowType;
  allowedInside: AllowedInside;
}

export interface GlobalVar {
  kind: RefType.GlobalVar;
  type: MarrowType;
}

export interface Callback {
  kind: RefType.Callback;
  args: MarrowType[];
}

export type Reference = RefInfo &
  (Block | Function | Command | Property | GlobalVar | Callback);

function allowedSpecific(block: string): AllowedInside {
  return { kind: "specific", block };
}

function allowedInLogic(): AllowedInside {
  return { kind: "logic" };
}

function refContainsString(searchTerm: string, ref: Reference) {
  return (
    ref.name.includes(searchTerm) ||
    ref.category.includes(searchTerm) ||
    ref.kind.includes(searchTerm)
  );
}

export function filterByKind(kind: RefType, references: Reference[]) {
  return references.filter(({ kind: refKind }) => kind === refKind);
}

export function filterByCategory(category: Category, references: Reference[]) {
  return references.filter(({ category: c }) => c === category);
}

export function filterByString(searchTerm: string, references: Reference[]) {
  searchTerm = searchTerm.trim().toLowerCase();
  return references.filter(ref => refContainsString(searchTerm, ref));
}

export const references: Reference[] = [
  {
    name: "defgame",
    kind: RefType.Block,
    category: Category.Game,
    details:
      "The top level mandatory block, which marks a file as a MarrowLang file. All other blocks must be defined inside.",
    required: true
  },
  {
    name: "variables",
    kind: RefType.Block,
    category: Category.Variables,
    details:
      "Create custom identifiers that hold a specific value and can change throughout the game.",
    required: true
  },
  {
    name: "players",
    kind: RefType.Block,
    category: Category.Players,
    details: "Defines information about the players in the game.",
    required: true
  },
  {
    name: "board",
    kind: RefType.Block,
    category: Category.Board,
    details:
      "Specifies the dimensions of the game board and the path that players can move along. Must include a `(w h)` tuple as the first argument.",
    required: true
  },
  {
    name: "triggers",
    kind: RefType.Block,
    category: Category.Logic,
    details: "React to events that take place at the start of each turn.",
    required: false
  },
  {
    name: "events",
    kind: RefType.Block,
    category: Category.Logic,
    details:
      "Combine multiple commands into a named abstraction, similar to procedures in other languages.",
    required: false
  },
  {
    name: "metadata",
    kind: RefType.Block,
    category: Category.Other,
    details:
      "Specifies the dimensions of the game board and the path that players can move along. Must include a `(w h)` tuple as the first argument.",
    required: false
  },
  {
    name: "description",
    kind: RefType.Property,
    category: Category.Game,
    details:
      "Sets a useful description for the game, which will be passed to clients.",
    type: string(),
    allowedInside: allowedSpecific("defgame")
  },
  {
    name: "max-turns",
    kind: RefType.Property,
    category: Category.Game,
    details:
      "Specifies the maximum number of turns that the game is allowed to run for without terminating.",
    type: int(),
    allowedInside: allowedSpecific("defgame")
  },
  {
    name: "turn-time-limit",
    kind: RefType.Property,
    category: Category.Players,
    details:
      "Specifies how many seconds a player is allowed to take to make their turn. If the player does not make their move within the specified limit, they forfeit their turn.",
    type: int(),
    allowedInside: allowedSpecific("defgame")
  },
  {
    name: "min-players",
    kind: RefType.Property,
    category: Category.Players,
    details:
      "Specifies the minimum number of players required to start the game.",
    type: int(),
    allowedInside: allowedSpecific("players")
  },
  {
    name: "max-players",
    kind: RefType.Property,
    category: Category.Players,
    details:
      "Specifies the maximum number of players who can take part in the game.",
    type: int(),
    allowedInside: allowedSpecific("players")
  },
  {
    name: "roles",
    kind: RefType.Property,
    category: Category.Players,
    details:
      "Specifies the different roles in the game, by which each player will be known. Roles must be unique. If minimum or maximum are set, then there must be enough roles listed to meet those conditions.",
    type: list(atom()),
    allowedInside: allowedSpecific("players")
  },
  {
    name: "start-order",
    kind: RefType.Property,
    category: Category.Players,
    details:
      "Sets the order in which players take their first turn. This defaults to random, but a list of role names can be passed instead. The order roles are listed is the order they will make their turn. The identifier as-written can be given to use the order specified in the roles command.",
    type: or([
      identifier("random"),
      identifier("as-written"),
      list(role())
    ]),
    allowedInside: allowedSpecific("defgame")
  },
  {
    name: "start-tile",
    kind: RefType.Property,
    category: Category.Players,
    details:
      "Sets the tile where players will start.  Optionally takes a list of tuples of the form `(role tile)`, allowing the starting tiles of individual players to be set. For example, `(start-tile (0 0) (a (1 1)))` will cause player a to start on tile `(1 1)`, and everyone else to start on tile `(0 0)`.",
    type: or([tile(), pair(role(), tile())]),
    allowedInside: allowedSpecific("defgame")
  },
  {
    name: "?current-player",
    kind: RefType.GlobalVar,
    category: Category.Players,
    details: "The name of the player currently making their turn.",
    type: role()
  },
  {
    name: "?current-tile",
    kind: RefType.GlobalVar,
    category: Category.Players,
    details:
      "The tile of the player currently making their turn. This effectively provides a shorter version of the expression `(player-tile ?current-player)`, as this is so common.",
    type: tile()
  },
  {
    name: "?board-width",
    kind: RefType.GlobalVar,
    category: Category.Board,
    details: "The current width of the board.",
    type: int()
  },
  {
    name: "?board-height",
    kind: RefType.GlobalVar,
    category: Category.Board,
    details: "The current height of the board.",
    type: int()
  },
  {
    name: "?current-turn",
    kind: RefType.GlobalVar,
    category: Category.Game,
    details: "The number of turns that have elapsed since the game began.",
    type: int()
  },
  {
    name: "handle-win",
    kind: RefType.Callback,
    category: Category.Players,
    details:
      "Called when a player wins the game. Takes the name of the winner as a single argument. By definition, this callback is guaranteed to only be called once, as the game ends when a player wins.",
    args: [role()]
  },
  {
    name: "handle-lose",
    kind: RefType.Callback,
    category: Category.Players,
    details:
      "Called when a player loses the game. Takes the name of the loser as a single argument.",
    args: [role()]
  },
  {
    name: "handle-timeup",
    kind: RefType.Callback,
    category: Category.Players,
    details:
      "Called when a player runs out of time to make their move, as defined by the `turn-time-limit` commands. Takes the name of the player as a single argument.",
    args: [role()]
  },
  {
    name: "player-tile",
    kind: RefType.Function,
    category: Category.Players,
    details: "The tile that the given role is currently positioned on.",
    args: [role()],
    returnType: tile(),
    example: ""
  },
  {
    name: "and",
    kind: RefType.Function,
    category: Category.Logic,
    details:
      "Logical `AND` conjunction. Returns `true` if all expressions evaluate themselves to `true`, otherwise `false`.",
    args: [list(bool())],
    returnType: bool(),
    example: "`(and (= 10 10) (!= 20 10))`"
  },
  {
    name: "or",
    kind: RefType.Function,
    category: Category.Logic,
    details:
      "Logical `OR` conjunction. Returns `true` if at least one expression evaluates to `true`, otherwise `false`.",
    args: [list(bool())],
    returnType: bool()
  },
  {
    name: "not",
    kind: RefType.Function,
    category: Category.Logic,
    details:
      "Logical `NOT` operation. Returns the logical negation of the given Boolean.",
    args: [bool()],
    returnType: bool()
  },
  {
    name: "concat",
    kind: RefType.Function,
    category: Category.Logic,
    details:
      'Concatenates all of the strings into one single string. For example, `(concat "Hello" " " "world")` returns "Hello world".',
    args: [list(string())],
    returnType: string()
  },
  {
    name: "last-roll",
    kind: RefType.Function,
    category: Category.Players,
    details: "Returns the last dice roll that took place for the given player.",
    args: [role()],
    returnType: int()
  },
  {
    name: "min",
    kind: RefType.Function,
    category: Category.Logic,
    details: "Returns the smallest number in the list.",
    args: [list(int())],
    returnType: int()
  },
  {
    name: "max",
    kind: RefType.Function,
    category: Category.Logic,
    details: "Returns the largest number in the list.",
    args: [list(int())],
    returnType: int()
  },
  {
    name: "choose-random",
    kind: RefType.Function,
    category: Category.Logic,
    details: "Returns a random item from the given list.",
    args: [list(or([int(), string(), role(), bool()]))],
    returnType: any()
  },
  {
    name: "rand-int",
    kind: RefType.Function,
    category: Category.Logic,
    details: "Returns a random number between the two arguments.",
    args: [int(), int()],
    returnType: int()
  },
  {
    name: "+",
    kind: RefType.Function,
    category: Category.Logic,
    details: "Returns the sum of all the numbers in the list.",
    args: [list(int())],
    returnType: int()
  },
  {
    name: "-",
    kind: RefType.Function,
    category: Category.Logic,
    details: "Subtracts every number in the list.",
    args: [list(int())],
    returnType: int()
  },
  {
    name: "*",
    kind: RefType.Function,
    category: Category.Logic,
    details: "Returns the product of all the numbers in the list.",
    args: [list(int())],
    returnType: int()
  },
  {
    name: "/",
    kind: RefType.Function,
    category: Category.Logic,
    details: "Performs integer division on all the numbers in the list.",
    args: [list(int())],
    returnType: int()
  },
  {
    name: "%",
    kind: RefType.Function,
    category: Category.Logic,
    details: "Returns the modulus of all the numbers in the list.",
    args: [list(int())],
    returnType: int()
  },
  {
    name: "=",
    kind: RefType.Function,
    category: Category.Logic,
    details:
      "Returns `true` if all the items in the list are equal, otherwise `false`.",
    args: [list(any())],
    returnType: bool()
  },
  {
    name: "!=",
    kind: RefType.Function,
    category: Category.Logic,
    details:
      "Returns `true` if none of the items in the list are equal, otherwise `false`.",
    args: [list(any())],
    returnType: bool()
  },
  {
    name: "move-to",
    kind: RefType.Command,
    category: Category.Players,
    details: "Moves the player to the given tile.",
    args: [role(), tile()],
    allowedInside: allowedInLogic()
  },
  {
    name: "skip-turn",
    kind: RefType.Command,
    category: Category.Players,
    details: "Makes the player skip the given number of turns.",
    args: [role(), int()],
    allowedInside: allowedInLogic()
  },
  {
    name: "win",
    kind: RefType.Command,
    category: Category.Players,
    details:
      "Makes the given player win the game. The `handle-win` callback will be called after this. Only one player may win the game.",
    args: [role()],
    allowedInside: allowedInLogic()
  },
  {
    name: "lose",
    kind: RefType.Command,
    category: Category.Players,
    details:
      "Makes the given player lose the game. Upon losing, the player will be removed, and the `handle-lose` callback will be called. Multiple players can lose the game.",
    args: [role()],
    allowedInside: allowedInLogic()
  },
  {
    name: "broadcast",
    kind: RefType.Command,
    category: Category.Communication,
    details: "Broadcasts the given message to all connected players.",
    args: [string()],
    allowedInside: allowedInLogic()
  },
  {
    name: "broadcast-to",
    kind: RefType.Command,
    category: Category.Communication,
    details: "Broadcasts the given message to the list of players.",
    args: [string(), list(role())],
    allowedInside: allowedInLogic()
  },
  {
    name: "increment!",
    kind: RefType.Command,
    category: Category.Variables,
    details:
      "Increments the given variable, mutating its value. The variable must contain an integer; if not, a warning will be raised.",
    args: [atom()],
    allowedInside: allowedInLogic()
  },
  {
    name: "decrement!",
    kind: RefType.Command,
    category: Category.Variables,
    details:
      "Decrements the given variable, mutating its value. The variable must contain an integer; if not, a warning will be raised.",
    args: [atom()],
    allowedInside: allowedInLogic()
  },
  {
    name: "set!",
    kind: RefType.Command,
    category: Category.Variables,
    details: "Sets the variable to the new value.",
    args: [atom(), any()],
    allowedInside: allowedInLogic()
  },
  {
    name: "set-meta!",
    kind: RefType.Command,
    category: Category.Other,
    details:
      "Set's the tile's metadata attribute to the given string. This will replace any value that may currently be set. The tile must be within the board's boundaries.",
    args: [tile(), atom(), string()],
    allowedInside: allowedInLogic()
  },
  {
    name: "path",
    kind: RefType.Command,
    category: Category.Board,
    details:
      "Generates a path from and to the given tiles. See the documentation for a full explanation of how to lay out the game board.",
    args: [tile(), tile()],
    allowedInside: allowedSpecific("board")
  },
  {
    name: "global",
    kind: RefType.Command,
    category: Category.Variables,
    details:
      "Defines a new global variable with the given default value. One copy will exist throughout the game.",
    args: [string(), any()],
    allowedInside: allowedSpecific("variables")
  },
  {
    name: "player",
    kind: RefType.Command,
    category: Category.Variables,
    details:
      "Defines a new player variable with the given default value. All players will have their own separate copy of this variable.",
    args: [string(), any()],
    allowedInside: allowedSpecific("variables")
  }
];
