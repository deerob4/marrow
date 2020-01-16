defmodule Language.Compiler do
  @moduledoc """
  Compiles the code.
  """

  require Language.Model
  require Logger

  import Language.Formatter, only: [format_identifier: 1]
  import Language.Interpreter, only: [reduce_expr: 1, reduce_args: 1]

  alias Language.Model, as: Game

  alias Language.Model.{
    Board,
    Card,
    Dice,
    Event,
    GlobalVariable,
    PlayerVariable,
    Role,
    Trigger
  }

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

  @callbacks [:handle_win, :handle_lose, :handle_timeup]

  defguardp is_printable_error(x) when is_bitstring(x) or is_boolean(x) or is_number(x)

  @doc """
  Returns a game from the tuple.
  """
  @spec from_ast(ast) :: {:ok, Game.t()} | {:error, String.t()}
  def from_ast(ast)

  def from_ast({:defgame, title, rest}) do
    with {%Game{} = game, storage} <-
           collect_commands(:defgame, rest, {%Game{title: title}, %{dice: %{}}}),
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

  defp eval(:defgame, {:callbacks, callbacks}, {%Game{} = game, storage}) do
    collect_commands(:callbacks, callbacks, {game, storage})
  end

  defp eval(:defgame, {:dice, dice}, {%Game{} = game, storage}) do
    collect_commands(:dice, dice, {game, storage})
  end

  defp eval(:player, {:roles, roles}, {%Game{} = game, storage}) do
    with %{} = roles <- collect_commands(:roles, roles, %{}),
         :ok <- Game.validate({:roles, roles}, game) do
      {%{game | roles: roles}, storage}
    end
  end

  # roles: [
  #   {:event, "a", [colour: ["red"]]},
  #   {:event, "b", [colour: ["blue"]]},
  #   {:event, "c", [colour: ["green"]]}
  # ]
  defp eval(:roles, {:event, name, _}, %{} = roles) when :erlang.is_map_key(name, roles) do
    {:error, "roles must be unique, but `#{format_identifier(name)}` is declared more than once"}
  end

  defp eval(:roles, {:event, name, role_details}, %{} = roles) do
    role = collect_commands(:role, role_details, %Role{name: name})

    with %Role{} <- role do
      Map.put(roles, name, role)
    end
  end

  defp eval(:role, {repr_type, [repr_value]}, %Role{} = role)
       when repr_type in [:image, :colour] do
    %{role | repr: {repr_type, repr_value}}
  end

  defp eval(:role, {:start_on, [{x, y}]}, %Role{} = role) do
    %{role | start_on: %Board.Tile{x: x, y: y}}
  end

  defp eval(:role, {:event, command, _}, %Role{name: name}) do
    invalid_role_command(name, command)
  end

  defp eval(:role, {:variable, {_, command}}, %Role{name: name}) do
    invalid_role_command(name, command)
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

  defp eval(:player, {:max_players, [max_players]}, {%Game{} = game, storage}) do
    with {:ok, max_players} <- reduce_expr(max_players),
         :ok <- Game.validate({:max_players, max_players}, game) do
      {%{game | max_players: max_players}, storage}
    end
  end

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
  defp eval(:player, {:start_tile, [{x, y} = tile]}, {%Game{} = game, storage}) do
    with :ok <- Game.validate({:start_tile, tile}, game) do
      {%{game | start_tile: %Board.Tile{x: x, y: y}}, storage}
    end
  end

  # If roles haven't been defined yet.
  defp eval(:player, {:start_tile, tiles}, {%Game{roles: roles} = game, storage})
       when map_size(roles) === 0 do
    storage = Map.put(storage, :start_tile, tiles)
    {game, storage}
  end

  # Variables

  defp eval(:variables, {:global, name, initial_value}, {%Game{} = game, storage}) do
    with {:ok, initial_value} <- reduce_expr(initial_value),
         :ok <- Game.validate({:global_var, name, initial_value}, game) do
      var = %GlobalVariable{name: name, value: initial_value}
      {%{game | global_vars: Map.put(game.global_vars, name, var)}, storage}
    end
  end

  # If the roles haven't been defined yet, we need to save this
  # player variable for post-processing.
  defp eval(:variables, {:player, _, _} = var, {%Game{roles: []} = game, storage}) do
    {game, add_to_storage(storage, :vars, var)}
  end

  # Otherwise they can just be set as normal.
  defp eval(:variables, {:player, name, initial_value}, {%Game{roles: roles} = game, storage}) do
    with %PlayerVariable{} = var <- generate_player_variables(name, roles, initial_value) do
      {%{game | player_vars: Map.put(game.player_vars, name, var)}, storage}
    end
  end

  defp eval(:board, {:path, from, to}, {%Game{} = game, %{board: %{paths: paths}} = storage}) do
    {game, put_in(storage, [:board, :paths], [{from, to} | paths])}
  end

  defp eval(:events, {name, args, body}, {%Game{events: events} = game, storage}) do
    # Search through and look for any custom events or invalid commands.
    case Enum.find(body, &match?({:event, _, _}, &1)) do
      {:event, invalid_command, _} ->
        {:error,
         "unknown command `#{format_identifier(invalid_command)}` found in the `#{
           format_identifier(name)
         }` event. Note that it is not possible to call one event from inside another."}

      nil ->
        events = Map.put(events, name, Event.new(args, body))
        {%{game | events: events}, storage}
    end
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
              %Card.Action{id: UUID.uuid4(), title: name, events: events}
            end)

          Map.put(card, :actions, actions)

        _unknown, _card ->
          {:error, "unexpected thing in card"}
      end)

    {%{game | cards: [%{card_struct | id: UUID.uuid4()} | game.cards]}, storage}
  end

  # Dice

  defp eval(:dice, {:sides, sides}, {%Game{} = game, storage}) do
    with {:ok, sides} <- reduce_args(sides) do
      {game, put_in(storage, [:dice, :sides], sides)}
    end
  end

  defp eval(:dice, {:reduce_by, [reduce_by]}, {%Game{} = game, storage}) do
    {game, put_in(storage, [:dice, :reduce_by], reduce_by)}
  end

  # Callbacks

  defp eval(:callbacks, {callback, [{:event, role_param, []}, body]}, {%Game{} = game, storage})
       when callback in @callbacks do
    event = Event.new([role_param], body)
    callbacks = Map.put(game.callbacks, callback, event)
    {%{game | callbacks: callbacks}, storage}
  end

  defp eval(:callbacks, {:event, callback, _}, {_game, _storage})
       when callback not in @callbacks do
    {:error,
     "the `callbacks` block may only include `handle-win`, `handle-lose`, or `handle-timeup`, but `#{
       format_identifier(callback)
     }` was found"}
  end

  defp eval(:callbacks, {callback, _}, {_game, _storage}) do
    {:error,
     "the `#{format_identifier(callback)}` callback only accepts a single `role` argument"}
  end

  defp eval(_, _, {:error, _reason} = error) do
    error
  end

  defp eval(block, {unknown_fun, _}, _game) when is_bitstring(unknown_fun) do
    {:error,
     "unknown command `#{format_identifier(unknown_fun)}` used inside the `#{
       format_identifier(block)
     }` block"}
  end

  # Some unknown commands might be parsed as variables, so redirect them to the
  # above error clause.
  defp eval(block, {:variable, {args, unknown_command}}, game) do
    eval(block, {unknown_command, args}, game)
  end

  defp eval(block, stray_input, _game) when is_printable_error(stray_input) do
    {:error, ~s(unknown input "#{stray_input}" found in the `#{format_identifier(block)}` block)}
  end

  defp eval(block, {builtin_command, _x}, _game) do
    {:error,
     "the `#{format_identifier(builtin_command)}` command cannot be used inside the `#{block}` block"}
  end

  defp eval(block, {var_type, _, _} = variable, _game) when var_type in @var_tags do
    errant_variable_definition(block, variable)
  end

  defp eval(block, {:event, event_name, _args}, _game) do
    {:error,
     "the custom event `#{format_identifier(event_name)}` was called in the `#{block}` block, but can only be used inside the `triggers` and `cards` blocks"}
  end

  defp eval(block, info, game) do
    IO.inspect(block)
    IO.inspect(info)
    IO.inspect(game)

    {:error, "something is wrong with your code inside the `#{format_identifier(block)}` block"}
  end

  # Card events are parsed as straight lists, but they need to
  # be in the callable AST syntax.
  # defp format_events([single_with_no_args]), do: [{single_with_no_args, []}]
  # defp format_events(otherwise), do: [otherwise]

  # The initial value has to be evaluated separately for each role;
  # otherwise, calls to functions like `rand-int` will produce the
  # same value for each player.
  defp generate_player_variables(var_name, roles, initial_value) do
    var = %PlayerVariable{name: var_name}

    Enum.reduce_while(roles, var, fn {role, _}, pv ->
      case reduce_expr(initial_value) do
        {:ok, value} ->
          {:cont, PlayerVariable.update_value(pv, role, value)}

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

  # defp collect_unique_start_tiles(tiles) do
  #   result = Enum.reduce_while(tiles, %{}, &collect_unique_start_tiles/2)

  #   with tiles when is_map(tiles) <- result do
  #     {:ok, tiles}
  #   end
  # end

  # defp collect_unique_start_tiles([value, _], _start_tiles) do
  #   error =
  #     with {:ok, value} <- reduce_expr(value) do
  #       {:error,
  #        "roles given to `start-tile` must be valid identifiers, but `#{value}` was given"}
  #     end

  #   {:halt, error}
  # end

  # defp collect_unique_start_tiles({:event, role, [{x, y}]}, start_tiles) do
  #   start_tiles = Map.put(start_tiles, role, {x, y})
  #   {:cont, start_tiles}
  # end

  # defp collect_unique_start_tiles(x, _start_tiles) do
  #   IO.inspect(x)
  #   {:halt, {:error, "invalid input given to `start-tile`."}}
  # end

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

  defp invalid_role_command(role_name, command) do
    {:error,
     "only the `colour`, `image`, and `start-on` commands may be used inside a role declaration, but `#{
       format_identifier(command)
     }` was used inside the declaration for `#{format_identifier(role_name)}`."}
  end

  # Once we've collected all the data into a constant access map,
  # we can bring it all together into somthing neater. Jed is
  # quite nice to talk to.
  defp postprocess(game, storage) do
    # TODO: verify that all the tiles are valid for the board.
    with {%Game{} = game, storage} <- do_postprocess(:start_tile, game, storage),
         {%Game{} = game, storage} <- do_postprocess(:board, game, storage),
         {%Game{} = game, storage} <- do_postprocess(:player_vars, game, storage),
         {%Game{} = game, storage} <- do_postprocess(:dice, game, storage),
         {%Game{} = game, storage} <- do_postprocess(:required_fields, game, storage),
         {%Game{} = game, storage} <- do_postprocess(:triggers, game, storage),
         {%Game{} = game, _storage} <- do_postprocess(:cards, game, storage) do
      game
    end
  end

  defp do_postprocess(:player_vars, game, %{vars: vars} = storage) do
    collect_commands(:variables, vars, {game, storage})
  end

  defp do_postprocess(:start_tile, %{start_tile: start_tile, roles: roles} = game, storage) do
    # This relies on the fact that all of the roles will have been
    # checked for consistency before getting here, so taking the first
    # is the same as taking any of the others.
    case {start_tile, Enum.take(roles, 1)} do
      {%Board.Tile{} = tile, [{_name, %Role{start_on: nil}}]} ->
        # Add the single start tile to all of the roles so that the rest of
        # the system doesn't have to know that it can be defined in two ways.
        roles = Map.new(roles, fn {name, role} -> {name, %{role | start_on: tile}} end)
        {%{game | roles: roles}, storage}

      {nil, [{_name, %Role{start_on: %Board.Tile{}}}]} ->
        {game, storage}

      {nil, [{_name, %Role{start_on: nil}}]} ->
        {:error,
         "the `start-tile` property must be defined if the `start-on` command is not explicitly called for each role"}

      {%Board.Tile{}, [{_name, %Role{start_on: %Board.Tile{}}}]} ->
        {:error,
         "if the `start-tile` property has been set, the `start-on` command cannot be used inside of role declarations, and vice-versa."}
    end
  end

  defp do_postprocess(:required_fields, game, storage) do
    required_fields = [:max_players, :min_players, :dice, :roles, :board]
    missing_field = Enum.find(required_fields, &(Map.get(game, &1) === nil))

    if missing_field do
      {:error, "the `#{format_identifier(missing_field)}` property must be defined"}
    else
      {game, storage}
    end
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

  defp do_postprocess(:board, game, %{board: %{dimensions: dimensions, paths: paths}} = storage) do
    start_tiles =
      case game.start_tile do
        nil -> Enum.map(game.roles, fn {_, %{start_on: %{x: x, y: y}}} -> {x, y} end)
        %{x: x, y: y} -> [{x, y}]
      end

    with {:ok, board} <- Board.new(dimensions, paths, start_tiles) do
      {%{game | board: board}, storage}
    end
  end

  defp do_postprocess(:cards, %{cards: cards} = game, storage) do
    # Events might have been parsed as global variables, so we
    # need to go through the card actions and rewrite them.
    cards = Enum.map(cards, &rewrite_card_actions/1)
    {Map.put(game, :cards, cards), storage}
  end

  defp do_postprocess(:dice, game, %{dice: %{sides: sides, reduce_by: reduce_by}} = storage) do
    with :ok <- Game.validate({:dice, sides, reduce_by}, game) do
      dice = %Dice{sides: sides, reduce_by: reduce_by}
      {Map.put(game, :dice, dice), storage}
    end
  end

  defp do_postprocess(_, game, storage), do: {game, storage}

  defp rewrite_trigger({condition, actions}) do
    actions = Enum.map(actions, &rewrite_action/1)
    {condition, actions}
  end

  defp rewrite_card_actions(%Card{actions: actions} = card) do
    actions =
      Enum.map(actions, fn %Card.Action{events: events} = action ->
        %{action | events: Enum.map(events, &rewrite_action/1)}
      end)

    Map.put(card, :actions, actions)
  end

  defp rewrite_action({:variable, {arg, event}}), do: {event, [arg]}
  defp rewrite_action({:event, event, args}), do: {event, args}
  defp rewrite_action(builtin), do: builtin
end
