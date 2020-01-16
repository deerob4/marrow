defmodule Language.Model do
  @moduledoc """
  Purely functional data structure representing a board game.

  This is the "semantic model", as referred to by Fowler.

  A user-provided DSL will be parsed into this form, where
  it will be taken by the server and used to host the game.
  """

  import Language.Formatter, only: [format_identifier: 1, format_number: 1]

  alias __MODULE__, as: Game
  alias Language.{Board, Card, Dice}
  alias Language.Model.{Board, Role}

  @player_range 1..60

  defimpl Jason.Encoder do
    def encode(game, opts) do
      # JSON doesn't accept arbitrary structures as keys, so we
      # need to convert the metadata tile keys to values.
      game = %{game | metadata: format_metadata(game.metadata)}
      game = Map.delete(game, :__struct__)
      Jason.Encode.map(game, opts)
    end

    defp format_metadata(metadata) do
      Map.new(metadata, fn {key, values} ->
        value_list =
          Enum.map(values, fn {coord, value} ->
            %{coord: coord, value: value}
          end)

        {key, value_list}
      end)
    end
  end

  defstruct title: "",
            description: "",
            max_turns: nil,
            turn_time_limit: nil,
            global_vars: %{},
            player_vars: %{},
            min_players: nil,
            max_players: nil,
            roles: %{},
            dice: nil,
            start_tile: nil,
            start_order: :random,
            events: %{},
            callbacks: %{},
            cards: [],
            triggers: [],
            metadata: %{},
            board: nil

  @type var_type :: :integer | :boolean | :string | :tile | :role

  @type variables :: %{required(String.t()) => var_type}

  @type start_order :: :random | :as_written | [String.t()]

  @type callback_name :: :handle_win | :handle_lose | :handle_timeup

  @typep proc_call :: {atom, [any]}

  @type event :: {[String.t()], [proc_call]}

  @type t :: %__MODULE__{
          title: String.t(),
          description: String.t(),
          max_turns: non_neg_integer,
          roles: [String.t()],
          turn_time_limit: non_neg_integer,
          global_vars: variables,
          player_vars: %{required(String.t()) => variables},
          min_players: non_neg_integer,
          max_players: non_neg_integer,
          start_tile: Board.tile() | %{String.t() => Board.tile()},
          start_order: start_order,
          board: Board.t(),
          cards: [Card.t()],
          events: %{required(String.t()) => event},
          callbacks: %{required(callback_name) => event},
          triggers: [any],
          metadata: %{required(String.t()) => %{required(Board.tile()) => [var_type]}},
          dice: [Dice.t()]
        }

  @doc """
  Returns `true` or `false` depending on whether or not `t`
  is a valid tile.

  Tiles are defined as 2-tuples, where both elements are
  integers greater than 0.
  """
  defguard is_tile(t)
           when is_tuple(t) and tuple_size(t) === 2 and is_integer(elem(t, 0)) and
                  is_integer(elem(t, 1)) and elem(t, 0) >= 0 and elem(t, 1) >= 0

  @doc """
  Returns `true` or `false` depending on whether or not
  `term` is a valid Marrow type.

  See the module docs for what constitutes a valid type.
  """
  defguard is_valid_term(term)
           when is_boolean(term) or is_bitstring(term) or is_integer(term) or is_tile(term)

  @doc """
  Validates whether the given details match the requirements.
  """
  @spec validate(tuple, Game.t()) :: :ok | {:error, String.t()}
  def validate(field, game)

  # Title

  def validate({:title, title}, %Game{})
      when is_bitstring(title),
      do: :ok

  def validate({:title, _title}, %Game{}),
    do: {:error, "the `title` property must be a string"}

  # Description

  def validate({:description, desc}, %Game{})
      when is_bitstring(desc),
      do: :ok

  def validate({:description, _desc}, %Game{}),
    do: {:error, "the `description` property must be a string"}

  # Max turns

  def validate({:max_turns, max_turns}, %Game{})
      when is_integer(max_turns) and max_turns > 0,
      do: :ok

  def validate({:max_turns, _max_turns}, %Game{}),
    do: {:error, "the `max-turns` property must be a positive integer"}

  # Turn limit

  def validate({:turn_time_limit, limit}, %Game{})
      when is_integer(limit) and limit > 0,
      do: :ok

  def validate({:turn_time_limit, _limit}, %Game{}),
    do: {:error, "the `turn-time-limit` property must be a positive integer"}

  # Min players

  def validate({:min_players, min_players}, %Game{max_players: max_players})
      when (max_players === nil or min_players <= max_players) and min_players in @player_range,
      do: :ok

  def validate({:min_players, min_players}, %Game{})
      when min_players not in @player_range,
      do:
        {:error,
         "the `min-players` property must be a number between #{format_range(@player_range)}"}

  def validate({:min_players, min_players}, %Game{max_players: max_players})
      when min_players > max_players,
      do: {:error, "the `min-players` property must not be greater than `max-players`"}

  # Max players

  def validate({:max_players, max_players}, %Game{min_players: min_players})
      when (min_players === nil or max_players >= min_players) and max_players in @player_range,
      do: :ok

  def validate({:max_players, max_players}, %Game{min_players: min_players})
      when max_players < min_players,
      do: {:error, "the `max-players` property must not be smaller than `min-players`"}

  def validate({:max_players, _max_players}, %Game{}),
    do:
      {:error,
       "the `max-players` property must a number be between #{format_range(@player_range)}"}

  # Roles

  def validate({:roles, roles}, %Game{max_players: max_players}) do
    with :ok <- role_length_matches_maximum_players(roles, max_players),
         :ok <- roles_have_representation(roles),
         :ok <- roles_have_consistent_start_on_values(roles) do
      :ok
    end
  end

  # Start tiles

  def validate({:start_tile, start_tile}, %Game{})
      when is_tile(start_tile),
      do: :ok

  def validate({:start_tile, _invalid_tile}, %Game{}),
    do: {:error, "a valid tile must be given to `start-tile`"}

  # Start order

  def validate({:start_order, start_order}, %Game{})
      when start_order in [:random, :as_written],
      do: :ok

  def validate({:start_order, start_order}, %Game{roles: roles}) do
    roles = Map.keys(roles)

    with :ok <- catch_unknown_values(roles, start_order),
         :ok <- catch_missing_values(roles, start_order) do
      :ok
    else
      {:unknown_values, values} ->
        {:error, "unknown roles given to `start-order`: #{format_list(values)}"}

      {:missing_values, values} ->
        formatted = format_list(values)
        connector = if length(values) === 1, do: "is", else: "are"

        {:error,
         "all roles must be listed in `start-order`, but #{formatted} #{connector} missing"}
    end
  end

  # Global vars

  def validate({:global_var, var_name, default}, %Game{})
      when is_valid_term(default) and is_bitstring(var_name),
      do: :ok

  def validate({:global_var, var_name, default}, %Game{})
      when not is_valid_term(default),
      do: {:error, "invalid variable type given to global variable `#{var_name}`"}

  def validate({:global_var, var_name, _default}, %Game{}),
    do:
      {:error,
       "global variable name must be a string, but `#{inspect(var_name)}` was given instead"}

  # Player vars

  def validate({:player_var, _var_name, default}, %Game{})
      when is_valid_term(default),
      do: :ok

  def validate({:player_var, var_name, _default}, %Game{}),
    do: {:error, "invalid variable type given to player variable `#{var_name}`"}

  # Dice

  def validate({:dice, sides, _reduce_by}, %Game{}) when length(sides) > 12,
    do:
      {:error,
       "A maximum of 12 dice can be specified, but #{format_number(length(sides))} were given"}

  def validate({:dice, _sides, reduce_by}, %Game{})
      when reduce_by not in [:sum, :multiply, :subtract] do
    {:error,
     "the `reduce-by` property only accepts the `sum`, `multiply`, and `subtract` literals"}
  end

  def validate({:dice, sides, _reduce_by}, %Game{}) do
    with {:type, true} <- {:type, Enum.all?(sides, &is_integer/1)},
         {:value, true} <- {:value, Enum.all?(sides, &(&1 in 1..12))} do
      :ok
    else
      {:type, _} -> {:error, "all dice sides must be integers"}
      {:value, _} -> {:error, "dice must have between 1 and 12 sides"}
    end
  end

  @doc """
  Checks whether `value` is the name of a player variable or event in
  the `game`.

  Returns `:player_variable`, `:event`, or `:none` depending on
  the value.
  """
  @spec valid_event_or_variable(t, any) :: :player_variable | :event | :none
  def valid_event_or_variable(game, value)

  def valid_event_or_variable(%Game{player_vars: vars}, value)
      when :erlang.is_map_key(value, vars),
      do: :player_variable

  def valid_event_or_variable(%Game{events: events}, value)
      when :erlang.is_map_key(value, events),
      do: :event

  def valid_event_or_variable(%Game{}, _), do: :none

  # Helpers

  defp roles_have_representation(roles) do
    bad_role =
      Enum.reduce_while(roles, :ok, fn {_, role}, acc ->
        case check_role_representation(role) do
          :ok -> {:cont, acc}
          error -> {:halt, error}
        end
      end)

    with :ok <- bad_role, do: :ok
  end

  defp check_role_representation(%Role{name: name, repr: nil}),
    do:
      {:error,
       "all roles must have a visual representation defined using the `colour` or `image` commands, but `#{
         format_identifier(name)
       }` does not"}

  defp check_role_representation(%Role{name: name, repr: {type, value}})
       when not is_bitstring(value),
       do:
         {:error, "the #{type} representation for `#{format_identifier(name)}` must be a string"}

  defp check_role_representation(%Role{}),
    do: :ok

  defp role_length_matches_maximum_players(roles, max_players)
       when map_size(roles) === max_players,
       do: :ok

  defp role_length_matches_maximum_players(roles, max_players) do
    role_length = map_size(roles)
    connector = if role_length === 1, do: "is", else: "are"

    {:error,
     "the number of roles given should match `max-players`, but #{format_number(role_length)} #{
       connector
     } listed instead of #{format_number(max_players)}"}
  end

  defp roles_have_consistent_start_on_values(roles)
       when map_size(roles) === 1,
       do: :ok

  defp roles_have_consistent_start_on_values(roles) do
    roles = Enum.map(roles, fn {_, role} -> role end)

    if consistent?(roles, false) do
      :ok
    else
      {:error,
       "if one role has been given an explicit `start-on` value then all the others must as well"}
    end
  end

  defp consistent?([], _), do: true
  defp consistent?([%Role{start_on: nil} | _], true), do: false
  defp consistent?([%Role{start_on: %Board.Tile{}}], false), do: false
  defp consistent?([%Role{start_on: %Board.Tile{}} | rest], _), do: consistent?(rest, true)
  defp consistent?([%Role{start_on: nil} | rest], false), do: consistent?(rest, false)

  def filter_error(enum, fun, error_atom) do
    case Enum.filter(enum, fun) do
      [] -> :ok
      error -> {error_atom, error}
    end
  end

  defp catch_unknown_values(actual, given) do
    filter_error(given, &(&1 not in actual), :unknown_values)
  end

  defp catch_missing_values(actual, given) do
    filter_error(actual, &(&1 not in given), :missing_values)
  end

  defp format_range(from..to) do
    "#{from} and #{to}"
  end

  def format_list([a]), do: "\"#{a}\""
  def format_list([a, b]), do: "\"#{a}\" and \"#{b}\""

  def format_list(list) do
    list_length = length(list)

    list
    |> Enum.with_index(1)
    |> Enum.reduce("", fn item, acc -> acc <> item_repr(item, list_length) end)
  end

  def item_repr({item, list_length}, list_length),
    do: "and \"#{item}\""

  def item_repr({item, index}, list_length) when index === list_length - 1,
    do: "\"#{item}\" "

  def item_repr({item, _}, _),
    do: "\"#{item}\", "

  @doc """
  Given a game model and a list of `used_roles`, returns a new
  model without any unused roles.
  """
  def remove_unused_roles(%Game{player_vars: _vars} = model, used_roles) do
    model
    |> Map.put(
      :player_vars,
      Map.new(model.player_vars, fn {name, var} ->
        {name, remove_role_from_var(var, used_roles)}
      end)
    )
    |> Map.put(:roles, remove_roles(model.roles, used_roles))
    |> Map.put(:start_order, update_start_order(model.start_order, used_roles))
  end

  defp remove_roles(roles, used_roles) do
    roles
    |> Enum.filter(fn {name, _} -> name in used_roles end)
    |> Map.new()
  end

  defp remove_role_from_var(%{values: values} = var, used_roles) do
    values = values |> Enum.filter(fn {role, _} -> role in used_roles end) |> Map.new()
    %{var | values: values}
  end

  defp update_start_order(:random, _), do: :random
  defp update_start_order(:as_written, _), do: :as_written
  defp update_start_order(start_order, roles), do: Enum.filter(start_order, &(&1 in roles))
end
