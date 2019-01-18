defmodule Language.Model do
  @moduledoc """
  Purely functional data structure representing a board game.

  This is the "semantic model", as referred to by Fowler.

  A user-provided DSL will be parsed into this form, where
  it will be taken by the server and used to host the game.
  """

  import Language.Formatter, only: [format_number: 1]

  alias __MODULE__, as: Game
  alias Language.{Board, Card, Dice}

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
            roles: [],
            dice: [],
            start_tile: nil,
            start_order: :random,
            events: %{},
            cards: [],
            triggers: [],
            metadata: %{},
            board: nil

  @type var_type :: :integer | :boolean | :string | :tile | :role

  @type variables :: %{required(String.t()) => var_type}

  @type start_order :: :random | :as_written | [String.t()]

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
      do: {:error, "the `min-players` property must be a number between #{format_range(@player_range)}"}

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
    with :ok <- roles_are_valid(roles),
         :ok <- roles_are_unique(roles),
         :ok <- role_length_matches_maximum_players(roles, max_players) do
      :ok
    end
  end

  # Start tiles

  def validate({:start_tile, tiles}, %Game{roles: roles}) when is_map(tiles) do
    with :ok <- catch_unknown_values(roles, Map.keys(tiles)),
         :ok <- catch_missing_values(roles, Map.keys(tiles)),
         :ok <- catch_invalid_tiles(tiles) do
      :ok
    else
      {:missing_values, values} ->
        formatted = format_list(values)
        connector = if length(values) === 1, do: "is", else: "are"

        {:error,
         "all roles must be listed in `start-tile`, but #{formatted} #{connector} missing"}

      {:unknown_values, values} ->
        {:error, "unknown roles were given to `start-tile`: #{format_list(values)}"}

      {:invalid_tiles, _tiles} ->
        {:error, "valid tiles must be given to `start-tile`"}
    end
  end

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

  # Helpers

  defp roles_are_valid(roles) do
    if Enum.any?(roles, fn r -> r === "" end) do
      {:error, "roles must not be empty strings"}
    else
      if Enum.all?(roles, &is_bitstring/1) do
        :ok
      else
        {:error, "roles must be valid identifiers"}
      end
    end
  end

  defp roles_are_unique(roles) do
    if roles |> Enum.uniq() |> length() === length(roles) do
      :ok
    else
      {:error, "roles must be unique"}
    end
  end

  defp role_length_matches_maximum_players(_roles, nil), do: :ok

  defp role_length_matches_maximum_players(roles, max_players)
       when length(roles) === max_players,
       do: :ok

  defp role_length_matches_maximum_players(roles, max_players) do
    connector = if length(roles) === 1, do: "is", else: "are"

    {:error,
     "then number of roles given should match `max-players`, but #{format_number(length(roles))} #{
       connector
     } listed instead of #{format_number(max_players)}"}
  end

  def filter_error(enum, fun, error_atom) do
    case Enum.filter(enum, fun) do
      [] -> :ok
      error -> {error_atom, error}
    end
  end

  defp catch_invalid_tiles(tiles) do
    filter_error(tiles, fn {_, tile} -> not is_tile(tile) end, :invalid_tiles)
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
end
