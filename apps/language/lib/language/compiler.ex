defmodule Language.Compiler do
  @moduledoc """
  Compiles the code.
  """

  require Language.Model
  require Logger

  import Language.Formatter, only: [format_identifier: 1, format_number: 1]
  import Language.Interpreter, only: [reduce_expr: 1]

  alias Language.Model, as: Game
  alias Language.Model.{Board, Card, Event, Trigger}

  @type ast :: tuple

  @typedoc """
  Type for the different blocks that commands in a description
  file can be placed in.
  """
  @type block :: :defgame | :player | :variables | :board

  # Builtin commands which perform an effect on the game state.
  # These are the only ones allowed in triggers, events, and
  # card actions/
  @effectful_builtins [
    :broadcast,
    :broadcast_to,
    :win,
    :lose,
    :move_to,
    :dice,
    :set!,
    :increment!,
    :decrement!,
    :set_meta!,
    :choose_card
  ]

  @var_tags [:player, :global]

  defguardp is_printable_error(x) when is_bitstring(x) or is_boolean(x) or is_number(x)

  @doc """
  Returns a game from the tuple.
  """
  @spec from_ast(ast) :: {:ok, Game.t()} | {:error, String.t()}
  def from_ast(ast)

  def from_ast({:defgame, title, rest}) do
    with {%Game{} = game, storage} <-
           collect_commands(:defgame, rest, {%Game{title: title}, %{}}),
         %Game{} = game <- postprocess(game, storage) do
      {:ok, game}
    end
  end

  defp collect_commands(block, ast, game) do
    Enum.reduce(ast, game, fn ast, game -> eval(block, ast, game) end)
  end

  # Basic properties.

  defp eval(:defgame, {:description, [desc]}, {game, storage}) do
    with {:ok, desc} <- reduce_expr(desc),
         :ok <- Game.validate({:description, desc}, game) do
      {%{game | description: desc}, storage}
    end
  end

  defp eval(:defgame, {:description, args}, _) when is_list(args) do
    bad_property_length(:description, args, 1)
  end

  defp eval(:defgame, {:max_turns, [max_turns]}, {%Game{} = game, storage}) do
    with {:ok, max_turns} <- reduce_expr(max_turns),
         :ok <- Game.validate({:max_turns, max_turns}, game) do
      {%{game | max_turns: max_turns}, storage}
    end
  end

  # defp eval(:defgame, {:max_turns, args}, _) when is_list(args) do
  #   bad_property_length(:max_turns, args, 1)
  # end

  defp eval(:defgame, {:turn_time_limit, [limit]}, {%Game{} = game, storage}) do
    with {:ok, limit} <- reduce_expr(limit),
         :ok <- Game.validate({:turn_time_limit, limit}, game) do
      {%{game | turn_time_limit: limit}, storage}
    end
  end

  # defp eval(:defgame, {:turn_time_limit, args}, _) when is_list(args) do
  #   IO.inspect args
  #   bad_property_length(:turn_time_limit, args, 1)
  # end

  # Top level blocks.

  defp eval(:defgame, {:variables, vars}, {%Game{} = game, storage}) do
    collect_commands(:variables, vars, {game, storage})
  end

  defp eval(:defgame, {:players, players}, {%Game{} = game, storage}) do
    collect_commands(:player, players, {game, storage})
  end

  defp eval(:defgame, {:board, dimensions, paths}, {%Game{} = game, storage}) do
    storage = Map.put(storage, :board, %{dimensions: dimensions, paths: []})
    collect_commands(:board, paths, {game, storage})
  end

  defp eval(:defgame, {:events, events}, {%Game{} = game, storage}) do
    collect_commands(:events, events, {game, storage})
  end

  defp eval(:defgame, {:cards, cards}, {%Game{} = game, storage}) do
    collect_commands(:cards, cards, {game, storage})
  end

  defp eval(:defgame, {:triggers, triggers}, {%Game{} = game, storage}) do
    collect_commands(:triggers, triggers, {game, storage})
  end

  defp eval(:defgame, {:metadata, metadata}, {%Game{} = game, storage}) do
    collect_commands(:metadata, metadata, {game, storage})
  end

  defp eval(:player, {:roles, roles}, {%Game{} = game, storage}) do
    with :ok <- Game.validate({:roles, roles}, game) do
      {%{game | roles: roles}, storage}
    end
  end

  # If events haven't been declared yet, save the triggers for validation late.r
  defp eval(:triggers, trigger, {%Game{events: events} = game, storage})
       when map_size(events) === 0 do
    {game, add_to_storage(storage, :triggers, trigger)}
  end

  defp eval(
         :triggers,
         {_, actions} = trigger,
         {%Game{events: events, triggers: triggers} = game, storage}
       ) do
    with :ok <- validate_trigger(actions, events) do
      {%{game | triggers: [trigger | triggers]}, storage}
    end
  end

  # Player properties.

  defp eval(:player, {:min_players, [min_players]}, {%Game{} = game, storage}) do
    with {:ok, min_players} <- reduce_expr(min_players),
         :ok <- Game.validate({:min_players, min_players}, game) do
      {%{game | min_players: min_players}, storage}
    end
  end

  # defp eval(:player, {:min_players, args}, _) when is_list(args) do
  #   bad_property_length(:min_players, args, 1)
  # end

  defp eval(:player, {:max_players, [max_players]}, {%Game{} = game, storage}) do
    with {:ok, max_players} <- reduce_expr(max_players),
         :ok <- Game.validate({:max_players, max_players}, game) do
      {%{game | max_players: max_players}, storage}
    end
  end

  # defp eval(:player, {:max_players, args}, _) when is_list(args) do
  #   bad_property_length(:max_players, args, 1)
  # end

  defp eval(:player, {:start_order, [start_order]}, {%Game{} = game, storage})
       when start_order in ["random", "as_written"] do
    start_order = String.to_existing_atom(start_order)
    {%{game | start_order: start_order}, storage}
  end

  defp eval(:player, {:start_order, start_order}, {%Game{} = game, storage}) do
    with :ok <- Game.validate({:start_order, start_order}, game) do
      {%{game | start_order: start_order}, storage}
    end
  end

  # If everyone starts on the same tile, like (start-tile (0 0)).
  defp eval(:player, {:start_tile, [{_, _} = tile]}, {%Game{} = game, storage}) do
    IO.inspect(tile)

    with :ok <- Game.validate({:start_tile, tile}, game) do
      {%{game | start_tile: tile}, storage}
    end
  end

  # If roles haven't been defined yet.
  defp eval(:player, {:start_tile, tiles}, {%Game{roles: []} = game, storage}) do
    storage = Map.put(storage, :start_tile, tiles)
    {game, storage}
  end

  # If the players are starting on different tiles, like
  # (start-tile (a (0 0)) (b (1 1)) (c (2 2))).
  defp eval(:player, {:start_tile, tiles}, {%Game{} = game, storage}) do
    with {:ok, tiles} <- collect_unique_start_tiles(tiles),
         :ok <- Game.validate({:start_tile, tiles}, game) do
      {%{game | start_tile: tiles}, storage}
    end
  end

  # Variables

  defp eval(:variables, {:global, name, initial_value}, {%Game{} = game, storage}) do
    with {:ok, initial_value} <- reduce_expr(initial_value),
         :ok <- Game.validate({:global_var, name, initial_value}, game) do
      vars = Map.put(game.global_vars, name, initial_value)
      {%{game | global_vars: vars}, storage}
    end
  end

  # If the roles haven't been defined yet, we need to save this
  # player variable for post-processing.
  defp eval(:variables, {:player, _, _} = var, {%Game{roles: []} = game, storage}) do
    {game, add_to_storage(storage, :vars, var)}
  end

  # Otherwise they can just be set as normal.
  defp eval(:variables, {:player, name, initial_value}, {%Game{roles: roles} = game, storage}) do
    with %{} = vars <- generate_player_variables(roles, initial_value) do
      {%{game | player_vars: Map.put(game.player_vars, name, vars)}, storage}
    end
  end

  defp eval(:board, {:path, from, to}, {%Game{} = game, %{board: %{paths: paths}} = storage}) do
    {game, put_in(storage, [:board, :paths], [{from, to} | paths])}
  end

  defp eval(:events, {name, args, body}, {%Game{events: events} = game, storage}) do
    events = Map.put(events, name, Event.new(args, body))
    {%{game | events: events}, storage}
  end

  defp eval(:metadata, {:event, category, tiles}, {%Game{metadata: metadata} = game, storage}) do
    value_map =
      Map.new(tiles, fn
        [{x, y}, value] ->
          {%Board.Tile{x: x, y: y}, value}

        _ ->
          {:error,
           "unexpected value in the `#{format_identifier(category)}` category of the `metadata` block"}
      end)

    metadata = Map.put(metadata, category, value_map)

    {%{game | metadata: metadata}, storage}
  end

  defp eval(:cards, [title | card], {game, storage}) do
    card_struct =
      Enum.reduce(card, %Card{title: title}, fn
        {:stack, [stack]}, card ->
          Map.put(card, :stack, stack)

        {:body, [body]}, card ->
          Map.put(card, :body, body)

        {:actions, actions}, card ->
          actions =
            Enum.map(actions, fn [name | events] ->
              {name, events}
            end)

          Map.put(card, :actions, actions)

        _unknown, _card ->
          {:error, "unexpected thing in card"}
      end)

    {%{game | cards: [card_struct | game.cards]}, storage}
  end

  defp eval(_, _, {:error, _reason} = error) do
    error
  end

  defp eval(_block, {unknown_fun, _}, _game) when is_bitstring(unknown_fun) do
    {:error, "unknown command `#{format_identifier(unknown_fun)}`"}
  end

  defp eval(block, stray_input, _game) when is_printable_error(stray_input) do
    {:error, ~s(unknown input "#{stray_input}" found in the `#{format_identifier(block)}` block)}
  end

  defp eval(block, {builtin_command, x}, _game) do
    IO.inspect(x)

    {:error,
     "the `#{format_identifier(builtin_command)}` command cannot be used inside the `#{block}` block"}
  end

  defp eval(block, {var_type, _, _} = variable, _game) when var_type in @var_tags do
    errant_variable_definition(block, variable)
  end

  defp eval(block, {:event, event_name, _args}, _game) do
    {:error,
     "the custom event `#{event_name}` was called in the `#{block}` block, but can only be used inside the `triggers` and `cards` blocks"}
  end

  defp eval(block, info, game) do
    IO.inspect(block)
    IO.inspect(info)
    IO.inspect(game)

    {:error, "something has gone wrong"}
  end

  defp bad_property_length(property, args, required_length) do
    arg_length = length(args)
    connective = if arg_length === 1, do: "was", else: "were"

    {:error,
     "the `#{format_identifier(property)}` property takes #{format_number(required_length)} argument, but #{
       format_number(arg_length)
     } #{connective} given instead."}
  end

  # Card events are parsed as straight lists, but they need to
  # be in the callable AST syntax.
  # defp format_events([single_with_no_args]), do: [{single_with_no_args, []}]
  # defp format_events(otherwise), do: [otherwise]

  # The initial value has to be evaluated separately for each role;
  # otherwise, calls to functions like `rand-int` will produce the
  # same value for each player.
  defp generate_player_variables(roles, initial_value) do
    Enum.reduce_while(roles, %{}, fn role, acc ->
      case reduce_expr(initial_value) do
        {:ok, value} ->
          {:cont, Map.put(acc, role, value)}

        error ->
          {:halt, error}
      end
    end)
  end

  defp errant_variable_definition(block, {var_type, var_name, value}) do
    with {:ok, value} <- reduce_expr(value) do
      var_name = format_identifier(var_name)
      inspected = "`(#{to_string(var_type)} #{var_name} #{inspect(value)})`"

      {:error,
       "variables may only be set within the `variables` block, but #{inspected} was called inside `#{
         block
       }`"}
    end
  end

  defp collect_unique_start_tiles(tiles) do
    result = Enum.reduce_while(tiles, %{}, &collect_unique_start_tiles/2)

    with tiles when is_map(tiles) <- result do
      {:ok, tiles}
    end
  end

  defp collect_unique_start_tiles([value, _], _start_tiles) do
    error =
      with {:ok, value} <- reduce_expr(value) do
        {:error,
         "roles given to `start-tile` must be valid identifiers, but `#{value}` was given"}
      end

    {:halt, error}
  end

  defp collect_unique_start_tiles({:event, role, [{x, y}]}, start_tiles) do
    start_tiles = Map.put(start_tiles, role, {x, y})
    {:cont, start_tiles}
  end

  defp collect_unique_start_tiles(x, _start_tiles) do
    IO.inspect(x)
    {:halt, {:error, "invalid input given to `start-tile`."}}
  end

  # A trigger is valid if:
  #
  # 1: all the actions are AST fragments that represent function calls,
  # and not just plain values; and
  #
  # 2: each action refers to either a built-in function or a
  # custom event.
  #
  def validate_trigger(actions, events) do
    with :ok <- check_for_plain_values(actions),
         :ok <- check_for_invalid_events(actions, events) do
      :ok
    else
      {:plain_value, value} ->
        {:error,
         "trigger actions must be commands or custom events, but the value `#{
           format_identifier(value)
         }` was found"}

      {:builtin_function, builtin} ->
        {:error,
         "only effectful commands can be used in trigger actions, but the `#{
           format_identifier(builtin)
         }` function was found"}

      {:variable_definition, variable} ->
        errant_variable_definition(:triggers, variable)

      {:invalid_event, event} ->
        {:error,
         "unknown custom event `#{format_identifier(event)}` found in the `triggers` block"}
    end
  end

  defp check_for_plain_values(actions) do
    case Enum.find(actions, &plain_value?/1) do
      nil -> :ok
      value -> {:plain_value, value}
    end
  end

  defp plain_value?({:event, _, _}), do: false
  defp plain_value?({x, y}) when is_integer(x) and is_integer(y), do: true
  defp plain_value?({_builtin, _args}), do: false
  defp plain_value?({:player, _, _}), do: false
  defp plain_value?(_plain_value), do: true

  defp check_for_invalid_events(commands, events) do
    case Enum.find(commands, &invalid_event?(&1, events)) do
      nil ->
        :ok

      {:variable, {_, custom_event}} ->
        {:invalid_event, custom_event}

      {builtin, _} ->
        {:builtin_function, builtin}

      {var_type, _, _} = variable when var_type in @var_tags ->
        {:variable_definition, variable}

      {:event, custom_event, _args} ->
        {:invalid_event, custom_event}
    end
  end

  # This is a huge hack. The parser parses code like `(hello nick)` as
  # {:variable, {"nick", "hello"}}, as though we were trying to access
  # a player variable. This same syntax is also used for custom event
  # calls though, so we need to match on the parsed syntax and check
  # the event call that way.
  defp invalid_event?({:variable, {_, event}}, events),
    do: not Map.has_key?(events, event)

  defp invalid_event?({:event, event, _args}, events),
    do: not Map.has_key?(events, event)

  defp invalid_event?({command, _}, _events),
    do: not (command in @effectful_builtins)

  defp invalid_event?(_, _), do: true

  defp add_to_storage(storage, key, value) do
    Map.update(storage, key, [value], fn values -> [value | values] end)
  end

  # Once we've collected all the data into a constant access map,
  # we can bring it all together into somthing neater. Jed is
  # quite nice to talk to.
  defp postprocess(game, storage) do
    # TODO: verify that all the tiles are valid for the board.
    with {%Game{} = game, storage} <- do_postprocess(:start_tile, game, storage),
         {%Game{} = game, storage} <- do_postprocess(:board, game, storage),
         {%Game{} = game, storage} <- do_postprocess(:player_vars, game, storage),
         {%Game{} = game, storage} <- do_postprocess(:required_fields, game, storage),
         {%Game{} = game, storage} <- do_postprocess(:triggers, game, storage),
         {%Game{} = game, storage} <- do_postprocess(:cards, game, storage),
         {%Game{} = game, _storage} <- do_postprocess(:format_tiles, game, storage) do
      game
    end
  end

  defp do_postprocess(:player_vars, game, %{vars: vars} = storage) do
    collect_commands(:variables, vars, {game, storage})
  end

  defp do_postprocess(:start_tile, game, %{start_tile: tiles} = storage) do
    eval(:player, {:start_tile, tiles}, {game, storage})
  end

  defp do_postprocess(:board, game, %{board: %{dimensions: dimensions, paths: paths}} = storage) do
    with start_tiles when is_list(start_tiles) <- extract_start_tiles(game),
         {:ok, board} <- Board.new(dimensions, {start_tiles, paths}) do
      {%{game | board: board}, storage}
    end
  end

  defp do_postprocess(:required_fields, game, storage) do
    required_fields = [:max_players, :min_players, :roles, :board]
    missing_field = Enum.find(required_fields, &(Map.get(game, &1) === nil))

    if missing_field do
      {:error, "the `#{format_identifier(missing_field)}` property must be defined"}
    else
      {game, storage}
    end
  end

  defp do_postprocess(:format_tiles, %{start_tile: start_tile} = game, storage) do
    start_tile =
      case start_tile do
        {x, y} ->
          %Board.Tile{x: x, y: y}

        tiles when is_map(tiles) ->
          Map.new(tiles, fn {key, {x, y}} -> {key, %Board.Tile{x: x, y: y}} end)
      end

    {%{game | start_tile: start_tile}, storage}
  end

  defp do_postprocess(:triggers, %{triggers: []} = game, %{triggers: triggers} = storage) do
    # We need to add a dummy event so that the map_size = 0
    # clause above isn't triggered.
    events = Map.put(game.events, nil, nil)
    game = Map.put(game, :events, events)

    with {%Game{} = game, storage} <- eval(:defgame, {:triggers, triggers}, {game, storage}) do
      # Remove the dummy event.
      events = Map.delete(game.events, nil)
      game = Map.put(game, :events, events)
      # Now we need to rewrite any custom command calls that might
      # have been parsed as player variables.
      triggers = Enum.map(game.triggers, &rewrite_trigger/1)
      triggers = Enum.map(triggers, fn {condition, events} -> Trigger.new(condition, events) end)
      {Map.put(game, :triggers, triggers), storage}
    end
  end

  defp do_postprocess(:cards, %{cards: cards} = game, storage) do
    # Events might have been parsed as global variables, so we
    # need to go through the card actions and rewrite them.
    cards = Enum.map(cards, &rewrite_card_actions/1)
    {Map.put(game, :cards, cards), storage}
  end

  defp do_postprocess(_, game, storage), do: {game, storage}

  defp rewrite_trigger({condition, actions}) do
    actions = Enum.map(actions, &rewrite_action/1)
    {condition, actions}
  end

  defp rewrite_card_actions(%Card{actions: actions} = card) do
    actions =
      Enum.map(actions, fn {name, event_list} ->
        {name, Enum.map(event_list, &rewrite_action/1)}
      end)

    Map.put(card, :actions, actions)
  end

  defp rewrite_action({:variable, {arg, event}}), do: {event, [arg]}
  defp rewrite_action({:event, event, args}), do: {event, args}
  defp rewrite_action(builtin), do: builtin

  defp extract_start_tiles(%{start_tile: nil}),
    do: {:error, "the `start-tile` property must be defined"}

  defp extract_start_tiles(%{start_tile: {_, _} = tile}), do: [tile]

  defp extract_start_tiles(%{start_tile: tiles}),
    do: Enum.map(tiles, fn {_, tile} -> tile end)
end
