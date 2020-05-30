defmodule Language.Docs do
  @moduledoc """
  Macros for automatically generating consistent and up-to-date
  documentation for language components.
  """

  @type kind :: :function | :command | :callback | :predefined_var | :block | :property

  @type category :: :board | :players | :variables | :logic | :other | :communication

  @type types :: :string | :integer | :role | :tile | :boolean

  @type example :: %{
          input: String.t(),
          output: String.t()
        }

  @type doc :: %{
          category: atom(),
          name: String.t(),
          kind: atom(),
          args: any(),
          return_type: any(),
          examples: [example()]
        }

  @static_docs [
    kinds: %{
      function: """
      Functions are named units of computation that return a result, often
      based on arguments passed in.
      """,
      command: """
      Commands are similar to functions, except that they do not return a value.
      Instead, they perform some kind of effect on the game's state or
      the game's session.

      Examples of effects include:

        * Updating a variable
        * Sending a message to players
        * Moving a player to another tile

      Since they do not return a value, using a command inside a function
      is not allowed. For example:

        `(+ 10 20 (increment! score))`

      Attempting to do so will result in a compilation error.
      """,
      predefined_var: """
      The runtime environment provides a number of predefined variables that
      reflect the current state of the game.

      Examples include:

        * `?current-player`
        * `?current-turn`

      To differentiate these from user-defined variables and definitions,
      they are prefixed with a question mark. Note that these variables
      cannot be mutated using the `set!` command; attempting to do so will
      result in a runtime error.
      """,
      block: """
      Each game file can be split into several different parts, such as
      player definitions, the board layout, and available events. These parts
      are known as __blocks__. Every declaration in the game can fit into one of
      the blocks.

      The following blocks are available:

        * `defgame`
        * `players`
        * `variables`
        * `events`
        * `triggers`
        * `callbacks`
        * `board`
        * `metadata`

      See the individual documentation entries for each block for more information.
      """,
      callback: """
      A __callback__ is a special type of trigger that is only called when a predefined
      event takes place, such as a player winning or losing the game. It is difficult
      or impossible to capture these events using Boolean expressions, making triggers inappropriate.

      All callbacks must be declared in a top-level `(callbacks)` block, and consist of the name of the
      event prefixed with handle-, optionally followed by the argument list.

      For example, if one wished to broadcast a message informing all remaining players that a player had
      lost the game, the following block could be used:

      ```
      (callbacks
        (handle-lose (loser)
        (broadcast (concat loser " has just lost!"))))
      ```

      Like events, callbacks may take an argument list. These are data associated with the callback; in
      the above example, the `loser` definition refers to the name of the player who has just lost.

      Callbacks can be called multiple times in a single turn; if several players lose at once, for example,
      the `handle-lose` callback will be called for each of them.
      """
    }
  ]

  def fetch_docs() do
    modules = [
      Language.Protocol.Functions
    ]

    protocol_docs =
      modules
      |> Enum.map(&fetch_docs_from_module/1)
      |> List.flatten()

    (protocol_docs ++ @static_docs) |> Map.new()
  end

  defp fetch_docs_from_module(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, _, _, docs} ->
        Enum.flat_map(docs, &extract_callback/1)

      _ ->
        []
    end
  end

  defp extract_callback({{:callback, name, _}, _, _, _, %{marrow: docs}}), do: [{name, docs}]
  defp extract_callback(_), do: []
end
