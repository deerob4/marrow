defmodule Language.Model.Board do
  @moduledoc """
  A struct and functions for representing a game board.

  Boards are the spaces on which games play out. They
  consist of a set of labelled tiles that players move
  around, with the goal of a game typically being to reach
  a certain tile or to go round a certain number of times,

  ## Board shapes

  In Marrow, boards may be either a square grid of a given
  width and length, or a set of connected tiles that form a
  travellable path. Observe:

    ### Grid

      o o o o F
      o o o o o
      o o o o o
      o o o o o
      S o o o o

    ### Unconnected path

      S o o o o o o
                  o
                  o o o o o o
                            o
                            o
              F o o o o o o o

    ### Connected path

      S o o o o o o o o o
      o                 o
      o                 o
      o o o o o o o o o o

  Where `S` represents the starting tile, `F` the finish,
  and `o` an ordinary tile.

  Boards may contain up to 625 tiles. The Marrow DSL
  contains utilities for easily generating boards, but in
  this struct all tiles are stored individually.

  ## Travel Direction

  For some board shapes, such as the grid example above,
  the direction that players travel in can be ambiguous.
  """

  alias __MODULE__

  @derive {Jason.Encoder, only: [:dimensions, :path_lines]}

  defstruct [:dimensions, :graph, :path_lines]

  @typedoc """
  An `x`, `y` Cartesian coordinate tuple specifying a
  single point on a 2D grid.
  """
  @type tile :: {non_neg_integer, non_neg_integer}

  @typedoc """
  Marks a path line from one tile to another tile.

  Paths must form either horizontal or vertical lines; that
  is, both coordinates must share either a common `x` or `y`
  value.
  """
  @type path_line :: {tile, tile}

  @type dimensions :: {non_neg_integer, non_neg_integer}

  @type t :: %__MODULE__{dimensions: dimensions, graph: Graph.t(), path_lines: [path_line]}

  @max_board_area 25 * 25

  @area_sqrt @max_board_area |> :math.sqrt() |> trunc()

  defmodule Dimensions do
    @derive {Jason.Encoder, only: [:width, :height]}

    @type t :: %__MODULE__{width: non_neg_integer, height: non_neg_integer}

    defstruct [:width, :height]

    defimpl Inspect do
      def inspect(%{width: w, height: h}, _opts) do
        "#{w}x#{h}"
      end
    end
  end

  defmodule Tile do
    @derive {Jason.Encoder, only: [:x, :y]}

    @type t :: %__MODULE__{x: integer, y: integer}

    defstruct x: 0, y: 0

    defimpl Inspect do
      def inspect(%{x: x, y: y}, _opts) do
        "(#{x} #{y})"
      end
    end
  end

  defmodule PathLine do
    @derive {Jason.Encoder, only: [:from, :to]}

    @type t :: %__MODULE__{from: Tile.t(), to: Tile.t()}

    defstruct [:from, :to]

    defimpl Inspect do
      def inspect(%{from: from, to: to}, _opts) do
        "(path #{inspect(from)} #{inspect(to)})"
      end
    end
  end

  @doc """
  Creates a board with tiles in a grid of the given size.

  A 2-tuple definining the width and height of the board
  should be passed as `dimensions`. These two values must
  not produce an area greater than #{@max_board_area}.

  With a blank grid in place, the `paths` along which
  players travel should be given. This is a list of tuples,
  each containing two tile coordinates. For example,
  `{{0, 0}, {5, 0}` creates a horizontal path from `{0, 0}`
  to `{5, 0}`.

   The paths must not exceed the boundaries set by
  `dimensions`.

  Returns `{:ok, board}` if `dimensions` is valid, otherwise
  `{:error, reason}`.

  ## Examples

      iex> Marrow.Board.new({100, 100}, [])
      {:error, "grids must not have an area larger than #{@max_board_area}"}

      iex> Marrow.Board.new({5, 5}, )

      iex> paths = [{{0, 0}, {0, 5}}, {{0, 5}, {0, 5}}]
      ...> Marrow.Board.new({5, 5}, paths)

  """
  @spec new(dimensions, [path_line], [tile]) :: {:ok, t} | {:error, String.t()}
  def new(dimensions, path_lines, start_tiles)

  def new({w, h}, _paths, _start_tiles) when w * h > @max_board_area,
    do:
      {:error,
       "board must not have an area larger than #{@max_board_area} tiles (#{@area_sqrt}x#{
         @area_sqrt
       })"}

  def new({w, h}, _paths, _start_tiles) when w < 1 or h < 1,
    do: {:error, "board size must be at least 1x1"}

  def new({_, _}, [], _),
    do: {:error, "at least one board path must be specified"}

  def new({_, _}, _, []),
    do: {:error, "at least one board starting point must be specified"}

  def new({w, h} = dimensions, path_lines, start_tiles) do
    with :ok <- ensure_positive_paths(path_lines),
         :ok <- catch_undeclared_start_points(path_lines, start_tiles),
         :ok <- validate_boundaries(dimensions, path_lines),
         :ok <- catch_diagonal_lines(path_lines),
         :ok <- catch_ambiguous_paths(path_lines),
         :ok <- ensure_continuous_paths(path_lines, start_tiles) do
      tiles = generate_tiles(path_lines)
      vs = generate_vertices(tiles)
      es = generate_edges(tiles)

      graph =
        Graph.new()
        |> Graph.add_vertices(vs)
        |> Graph.add_edges(es)

      board = %Board{
        dimensions: %Dimensions{width: w, height: h},
        graph: graph,
        path_lines: generate_path_structs(path_lines)
      }

      {:ok, board}
    end
  end

  # For each set of start/end coordinates, generate the coordinates between them.
  defp generate_tiles(path_lines) do
    path_lines
    |> Enum.reverse()
    |> Enum.map(&generate_path/1)
    |> List.flatten()
  end

  # Horizontal paths.
  defp generate_path({{x1, y}, {x2, y}}), do: for(x <- x1..x2, do: {x, y})

  # Vertical paths.
  defp generate_path({{x, y1}, {x, y2}}), do: for(y <- y1..y2, do: {x, y})

  # The vs of the grpah is just a list of the unique tiles.
  defp generate_vertices(tiles), do: Enum.uniq(tiles)

  defp generate_edges(tiles) do
    tiles
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(&List.to_tuple/1)
    |> Enum.reject(&match?({x, x}, &1))
  end

  defp catch_undeclared_start_points(path_lines, start_points) do
    paths = Enum.map(path_lines, fn {from, _to} -> from end)
    undeclared_start = Enum.find(start_points, &(&1 not in paths))

    if undeclared_start do
      {:error,
       "start tiles must be declared in path lines, but #{format_tile(undeclared_start)} is not"}
    else
      :ok
    end
  end

  defp ensure_continuous_paths(paths, start_points) do
    froms = Enum.map(paths, fn {from, _to} -> from end)
    tos = Enum.map(paths, fn {_from, to} -> to end)

    broken_path = Enum.find(froms, &(&1 not in tos and &1 not in start_points))

    if broken_path do
      {:error,
       "paths must be continuous, but #{format_tile(broken_path)} is unreachable from the declared tiles"}
    else
      :ok
    end
  end

  # Make sure none of the paths contain any negative values.
  defp ensure_positive_paths(paths) do
    negative_path =
      Enum.find(paths, fn {{x1, y1}, {x2, y2}} -> x1 < 0 or x2 < 0 or y1 < 0 or y2 < 0 end)

    if negative_path do
      {:error,
       "coordinates must be positive, but #{format_path_line(negative_path)} contains a negative"}
    else
      :ok
    end
  end

  # Ensure that only horizontal and vertical paths are allowed.
  defp catch_diagonal_lines(paths) do
    if diagonal = Enum.find(paths, &diagonal?/1) do
      {:error,
       "paths must be either horizontal or vertical, but #{format_path_line(diagonal)} forms a diagonal line"}
    else
      :ok
    end
  end

  # If either an x or y coord isn't the same, then it must be a diagonal.
  defp diagonal?({{x, _y1}, {x, _y2}}), do: false
  defp diagonal?({{_x1, y}, {_x2, y}}), do: false
  defp diagonal?({{_x1, _y1}, {_x2, _y2}}), do: true

  # # Ensure that no path line exceeds the specified grid boundaries.
  defp validate_boundaries({w, h}, paths) do
    invalid_boundary =
      Enum.find(paths, fn {{x1, y1}, {x2, y2}} ->
        x1 > w or x2 > w or y1 > h or y2 > h
      end)

    if invalid_boundary do
      {:error, "path line #{format_path_line(invalid_boundary)} exceeds the grid boundaries"}
    else
      :ok
    end
  end

  # # Ensure that each tile only connects to one other tile, to prevent
  # # ambiguities around where players can move.
  defp catch_ambiguous_paths(paths) do
    froms = Enum.map(paths, fn {from, _to} -> from end)
    ambiguous_path = Enum.find(froms, fn x -> Enum.count(froms, &(&1 === x)) > 1 end)

    if ambiguous_path do
      {:error,
       "paths must not be ambiguous, but #{format_tile(ambiguous_path)} is connected to multiple tiles"}
    else
      :ok
    end
  end

  defp generate_path_structs(path_lines) do
    Enum.map(path_lines, fn {{x1, y1}, {x2, y2}} ->
      from = %Tile{x: x1, y: y1}
      to = %Tile{x: x2, y: y2}
      %PathLine{from: from, to: to}
    end)
  end

  def please_generate_path(%Board.PathLine{from: %{x: x1, y: y}, to: %{x: x2, y: y}}),
    do: for(x <- x1..x2, do: %Board.Tile{x: x, y: y})

  def please_generate_path(%Board.PathLine{from: %{x: x, y: y1}, to: %{x: x, y: y2}}),
    do: for(y <- y1..y2, do: %Board.Tile{x: x, y: y})

  # Vertical paths.

  @doc """
  Adds a new series of paths to the board.

  The new paths must join at some point with the existing
  paths, to ensure that players can reach them.
  """
  @spec add_paths(t, [path_line]) :: {:ok, t} | {:error, String.t()}
  def add_paths(board, _paths) do
    {:ok, board}
  end

  @doc """
  Removes the specified path from the board if it exists.
  """
  @spec break_path(t, path_line) :: {:ok, t} | {:error, String.t()}
  def break_path(board, _path) do
    {:ok, board}
  end

  def format_path_line({{x1, y1}, {x2, y2}}), do: "`(path (#{x1} #{y1}) (#{x2} #{y2}))`"

  def format_tile({x, y}), do: "`(#{x} #{y})`"
  def format_tile(%Tile{x: x, y: y}), do: "`(#{x} #{y})`"

  @doc """
  For any given `tile`, returns the tile one space ahead.
  Alternatively returns `nil` if `tile` is the end of the
  board and there is no way forward.
  """
  @spec next_tile(t, tile) :: tile | nil
  def next_tile(%Board{graph: graph}, tile) do
    case Graph.out_neighbors(graph, tile) do
      [next_tile] -> next_tile
      [] -> nil
    end
  end

  def path_to_tile(%Board{graph: graph}, from, to) do
    tiles = Graph.dijkstra(graph, from, to)
    Enum.map(tiles, fn {x, y} -> %Tile{x: x, y: y} end)
  end

  @doc """
  Returns `true` if `tile` exists on the board, otherwise `false`.
  """
  @spec valid_tile?(t, tile) :: boolean
  def valid_tile?(%Board{graph: graph} = _board, tile) do
    Graph.has_vertex?(graph, tile)
  end
end
