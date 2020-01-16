# MarrowLang

A simple, S-expression based DSL for creating board games. See below for
a full discussion of the language and its features.

## Lexical Structure

### White Space

The lexer defines white space as the ASCII space character, the newline
character, the horizontal tab character, and the form feed character.
All white space is ignored.

### Comments

Lines beginning with the `;` character are treated as comments and
discarded by the lexer. Comments must begin on their own line.
Multi-line comments are not supported.

### Keywords

Certain keywords are reserved for pre-defined functions and global
variables, and so may not be used as custom identifiers. Any attempt to
do so will result in a compilation error. These include the following:

defgame if and or not increment decrement win lose dice max-turns
turn-time-limit dice sum subtract broadcast random events players
triggers board line

### Literals

A range of common literal types are supported. All literals must be
enclosed in at least one list.

#### String Literals

Strings consist of a sequence of ASCII characters enclosed in quotation
marks. The full set of printable characters (32 - 127) are supported, as
are the extended set of characters (161 - 255). The escape sequences
`\n` and `\t` provide new lines and horizontal tabs, respectively.

**Examples**: `"hello\nworld" "rødgrød med fløde" "(+ 10 20)"`

#### Integer Literals

Integers are expressed in base 10, and consist of a sequence of digits
from 0 - 9. The BEAM VM stores numbers using arbitrary precision
arithmetic, thus the only upper size limit is determined by the memory
of the machine. Negative numbers are achieved by placing a `-` sign in
front of the first digit. Floating-point values are not supported.

**Examples**: `-298 -1 0 8 201 98348934`

#### Boolean Literals

Booleans are represented using the atomic values `true` and `false`.

#### Identifier Literals

Identifiers are constant values where the value represents the contents.
They are analogous to atoms in the BEAM. They consist of a sequence of
lower-case letters from `a - z`, optionally interspersed with hyphens.
Exclamation marks may appear at the end, and question marks at the
beginning or end. All functions, variables, and other keywords are
represented as identifiers.

**Examples**: `monopoly board-game-maker treehouse`

#### List Literals

Lists in `MarrowLang` are heterogeneous, recursive linked lists that can
store any literal or expression. Lists are formed by enclosing zero or
more literal values within the `(` and `)` characters, separated by
spaces. Lists that consist solely of two integers, such as `(10 10)`,
are parsed as board tile coordinates, and so should be avoided for other
purposes.

**Examples**: `() (pop) (+ 10 (* 20 (- 20 18)))`

## Language Concepts

The language includes several concepts familiar to all, as well as some
that are specific to board games. This part outlines the key forms of
abstraction that the language provides.

### Variables and Definitions

Almost every non-trivial game needs some way of storing and updating
values associated with events. `MarrowLang` provides several constructs
to achieve this behaviour.

#### Variables

Variables in `MarrowLang` perform a similar function to those in most
other languages, in that they associate a custom identifier with a
mutable value. Despite this, there are some important differences owing
to the board-game context. There are three types of variable, all with
different use-cases: *predefined*, *global*, and *player*.

##### Global Variables

Global variables are essentially identical to variables in other
languages, and can be used to keep track of arbitrary values that might
change throughout a game. The epithet *global* is used because
`MarrowLang` does not have any concept of scope, and these variables can
be used anywhere in the game file.

Variables must be declared in a top level `(variables)` block,
consisting of a list of *key-value* statements, where the key is the
variable name and the value is the initial state. For example, the
block:

```clojure
(variables
  (circuits 0)
  (door-opened (not true)))
```

creates two variables, *circuits* and *door-opened*, with initial values
of `0` and `false` respectively. These variables can be accessed by
writing their name at any point where a literal value would be used. For
example, the expression `(+ 10 score)` evaluates to 10 plus the value of
the *score* variable.

Updating a variable's value is achieved using the `set!` command. This
takes the name of a variable, followed by an expression that evaluates
to the new value. For example, `(set!` `circuits (+ circuits 1))`
increments the variable *circuits*. There are some additional commands
that apply common mutations to variables in a more concise way; the
command `(increment!` `circuits)`, for example, performs the above
example in one step.

##### Player Variables

Often a game may need to keep track of individual values for each
player. The canonical example is health: each player might have an
integer representing their current health level, which can change
depending on actions they take. One player's health is independent of
another's, so a single global variable will not do; and it is
impractical to create $pv$ variables for each player.

The `player-var` command provides convenient syntax to solve these
problems. It works in the same way as `var`, but creates a unique
instance of that variable for every player. For example, the command
`(player-var health 0)` creates variables such that for every player in
the game there exists a variable *health* that is initialised to 0.
Accessing a variable is achieved by applying the player name to the
variable name. For example, `(health a)` will return player *a*'s
current health value.

Two utility functions, `min` and `max`, can be used with player
variables to return the player with the largest / smallest value of that
variable respectively.

##### Predefined Variables {#sec:predefined-variables}

The runtime environment provides a number of predefined variables that
reflect the current state of the game. To differentiate these from
user-defined variables and definitions, they are prefixed with a
question mark. These variables cannot be directly mutated using the
`set!` command. A full list of predefined variables can be found in the
language reference.

#### Definitions {#sec:definitions}

Definitions are literal values associated with identifiers that cannot
be modified. They are useful for giving names to fixed values used
throughout the game where the value itself may be unclear.

All definitions must be defined in a top-level `(definitions)` block,
containing a list of *key-value* definitions. For example:

```clojure
(definitions
  (attack-damage 5)
  (minimum-lives (+ 1 1))
```

The `MarrowLang` compiler implements constant folding and propagation,
so these definitions will be replaced at a grammar level.

### Triggers, Events, and Callbacks

In any game, interaction is required. In `MarrowLang`, there are three
different ways of achieving this, each depending on the context.

#### Triggers

During the course of a board game, it is desirable to have events occur
depending on different factors. For example, landing on a certain tile
might send the player back two spaces, or reaching a certain score may
make the player immediately win. Triggers are the means by which such
events can be expressed in `MarrowLang`.

Triggers consist of a Boolean expression and a series of commands. Each
turn, the expression of each trigger will be evaluated, and if it
reduces to `true`, the commands will be executed. For example, consider
the following:

```clojure
(triggers
  ((= ?player-tile (10 5))
    (move-to (10 6) ?current-player)))
```

This trigger checks whether the current player is on tile `(10 5)`. If
they are, then they are moved forward one space to `(10 6)`. Any Boolean
expression may be used as a trigger, and any valid combination of
commands and events may be used in the body. This makes it possible to
create board games with complex logic.

#### Events

Events provide a means of grouping several commands into one named
abstraction, cutting down on repetitive code and allowing for reuse.
They are conceptually very similar to procedures in mainstream
programming languages.

A simple example of an event might be as follows:

```clojure
(climb (tile)
  (move-to tile ?current-player)
  (increment! (climbs ?current-player)))
```

This creates an event called `climb` with a single argument, which calls
both the `move-to` and `increment!` commands in sequence.

Arguments may be given to events, as seen in the `(tile)` parameter list
above. These arguments are exposed as local variables within the event
body, and replaced with the actual value passed in at runtime. If an
event takes no arguments, then an empty list `()` should be used.

Events can use the full range of built in commands, functions,
variables, and expressions; and may be used in triggers and callbacks
wherever built-in commands might be used.

Certain limitations exist. Events are procedures in the technical sense,
as opposed to functions; and so may not return a value. Like all
commands, they have an implicit return type of *unit*. Additionally,
events may not call other events, including themselves.

#### Callbacks

A *callback* is a special type of trigger that is only called when a
predefined event takes place, such as a player winning or losing the
game. It is difficult or impossible to capture these events using
Boolean expressions, making triggers inappropriate.

All callbacks must be declared in a top-level `(callbacks)` block, and
consist of the name of the event prefixed with `handle-`, optionally
followed by the argument list.

For example, if one wished to broadcast a message informing all
remaining players that a player had lost the game, the following block
could be used:

```clojure
(callbacks
  (handle-lose (loser)
    (broadcast (concat loser " has just lost!"))))
```

Like events, callbacks may take an argument list. These are data
associated with the callback; in the above example, the `loser`
definition refers to the name of the player who has just lost.

Callbacks can be called multiple times in a single turn; if several
players lose at once, for example, the `handle-lose` callback will be
called for each of them.

For a list of all the available callbacks, see the language reference.

### Boards {#sec:boards}

All games take place on a *board*, which is a 2D Cartesian grid of a
custom width and height, composed of $wh$ tiles. The maximum board size
is 25$\times$25, i.e. 625 tiles. Each player begins and ends their turn
on one of these tiles, and all gameplay occurs by moving from tile to
tile.

The board may be thought of as a simple directed path graph, where each
tile (vertex) is connected to at most one other tile; and there exists
an unambiguous path from the designated start tiles to the designated
end tiles. Cyclic boards, as in games like Monopoly, are also allowed.

Note that width and height are specified starting at 1, but the
coordinates begin at 0. The origin is in the top left hand corner.

#### Defining Movement

Movement across a board is expressed by defining a series of
uni-directional paths between two tile coordinates. Consider the
following example:

```clojure
(board (5 1) (path (0 0) (4 0)))
```

This creates a small 5$\times$1 board with a single path running
horizontally from the tiles `(0 0)` to `(4 0)`. Expanded out, the full
line looks thus:
`(0 0)`$\rightarrow$`(1 0)`$\rightarrow$`(2 0)`$\rightarrow$`(3 0)`$\rightarrow$`(4 0)`.
If a player starts at tile `(0 0)` and they were to roll a 2, they would
end up at tile `(2 0)`.

The `path` command can only create lines in either a horizontal or
vertical direction. Diagonal lines are invalid. Thus, to create a board
that allows for several directions, several `path` commands can be used
in a row, as below:

```clojure
(board (5 5)
  (path (0 0) (4 0))
  (path (4 0) (4 4))
  (path (4 4) (0 4))
  (path (0 4) (0 0)))
```

This example creates a 5$\times$5 board where a path-line has been
created clockwise around the perimeter of the board. Any combination of
`path` commands is allowed, as long as they:

-   are within the grid boundaries

-   form either a horizontal or vertical line

-   are unambiguous; that is, that each tile connects to only one other
    tile, unless they are forming a cycle.

-   form part of a single, continuous path

#### Tile Metadata

It is often useful to attach certain descriptive metadata to a tile, in
order to enhance the game beyond what can be expressed with logic.
Examples of such data include text labels and background graphics.

Default metadata, representing the game at its start point, can be
defined by using the `metadata` block, as below:

```clojure
(metadata
  (label
    ((0 0) "Start")
    ((5 5) "End"))
  (background
    ((0 1) "img/01.png")))
```

This command sets the `label` attribute of tiles `(0 0)` and `(5 5)` to
appropriate text, and the `background` attribute of tile `(0 1)` to an
image link. Any attribute name is allowed, as long as it follows the
syntax rules for identifiers. These metadata will then be sent to
clients at the beginning of the game, to be used as they see fit.

It is possible to dynamically alter tile metadata during gameplay using
the `set-meta` command:

```clojure
(set-meta (0 0) label "Changed!")
```

This can be used in triggers and events to, for example, change a tile's
text in response to a player being removed from the board. Thus, highly
dynamic boards can be constructed.

### Dice

Like in most board games, movement around the game board in `MarrowLang`
games is controlled using dice. At the start of each turn, dice are
rolled, the outcome of which is the number of tiles the player can move.

Dice can be controlled in the game through the `dice` command, which
takes as arguments the number of dice, the number of sides each die has,
and the reduce function that specifies how the different rolls will be
combined. For example, `(dice 2 6 sum)` stipulates that two dice, each
with six sides, will be rolled; and the rolls will be summed together to
arrive at the final value.

The `dice` command must be called at least once in the toplevel block,
to set the default values. It can also be called in events and triggers,
allowing the values to change depending on game events.