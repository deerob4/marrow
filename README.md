# Marrow: An Interactive Board-Game Designer

Marrow is a language, server protocol, and associated web application for designing board games and playing them against other people. It specifically focuses on so called "roll and move" games: those where players throw some dice, and move units around a set path on a tiled board. Scripted or random events can take place on certain tiles. It's named after the two inventors of Monopoly, Elizabeth Magie and Charles Darrow.

Due to being very early in development, the feature-set of Marrow is still somewhat in flux. Despite this, there are certain features that are almost certain to be included; they have been split up into their appropriate categories for easier organisation.

## Language
A simple DSL for expressing the rules and structure of a board game. It should look something like this:

```clojure
(defgame "New Game"
    (description "A fun game that lots of people can play.")

    (players
      (min-players 2)
      (max-players 3)
      (roles a b c)
      (start-tile (0 0)))

    (board (5 5)
      (path (0 0) (4 0))
      (path (4 0) (4 4))
      (path (4 4) (0 4))
      (path (0 4) (0 0))))
```

Some features of the system include:

+ Support for basic board-game rules like moving forward or backwards \textit{n} tiles or capturing pieces.
+ Abstract variables such as score or health can be introduced, which can be modified according to some tile-based event.
+ Custom winning and losing conditions based on these variables or board position.

+ Simple drag-n-drop interface for placing grid tiles and defining the direction of movement.
+ Multiple board shapes - initially square, hexagonal, and triangular.
+ Provide paths that only open up after certain conditions have been met.
+ Automatic validation to ensure that it's not possible to design a board where players can become stuck.

## Protocol

It would be nice for the server to define some sort of open protocol that any client could consume. This could potentially open the way to mobile apps, or even some sort of cloud-connected harware. That'd be really cool.

## Technical

Marrow is a story of several chapters. The first, the server implementation, is in Elixir. More on this anon.
