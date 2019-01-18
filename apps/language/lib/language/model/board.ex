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
  @spec new(dimensions, {[tile], [path_line]}) :: {:ok, t} | {:error, String.t()}
  def new(dimensions, paths, opts \\ [])

  def new({w, h}, _paths, _opts) when w * h > @max_board_area do
    area_root = @max_board_area |> :math.sqrt() |> trunc

    {:error,
     "board must not have an area larger than #{@max_board_area} tiles (#{area_root}x#{area_root})"}
  end

  def new({w, h}, _paths, _opts) when w < 1 or h < 1,
    do: {:error, "board size must be at least 1x1"}

  def new({_, _}, {_, []}, _opts),
    do: {:error, "at least one board path must be specified"}

  def new({_, _}, {[], _}, _opts),
    do: {:error, "at least one board starting point must be specified"}

  def new({w, h} = _dimensions, {_start_points, paths}, _opts) do
    _whole_board = paths |> Enum.map(&generate_path/1) |> List.flatten() |> Enum.uniq()

    with :ok <- ensure_positive_paths(paths) do
      #  :ok <- catch_undeclared_start_points(start_points, whole_board),
      #  :ok <- validate_boundaries(dimensions, paths),
      #  :ok <- catch_diagonal_lines(paths),
      #  :ok <- catch_ambiguous_paths(paths),
      #  :ok <- ensure_continuous_paths(start_points, paths) do
      path_lines =
        Enum.map(paths, fn {{x1, y1}, {x2, y2}} ->
          from = %Tile{x: x1, y: y1}
          to = %Tile{x: x2, y: y2}
          %PathLine{from: from, to: to}
        end)

      # For each set of start/end coordinates, generate the
      # coordinates between them.
      # paths = paths |> Enum.map(&generate_path/1) |> List.flatten()
      # The path list above may contain duplicates and
      # nested lists, so get rid of those to produce a list
      # of vertices for the graph.
      # vs = Enum.uniq(paths)
      # The edges are a bit more complex.
      # cyclic? = Keyword.get(opts, :cyclic?, false)
      # es =
      #   paths
      #   |> Enum.chunk_every(2, 1, if(cyclic?, do: paths, else: []))
      #   |> Enum.map(&List.to_tuple/1)
      #   |> Enum.reject(fn
      #     {{x, y}, {x, y}} -> true
      #     # {{_, _}} -> true and not cyclic? # true and not cyclic?
      #     _ -> false
      #   end)

      # Finally put everything together into a graph.
      # graph =
      #   Graph.new()
      #   |> Graph.add_vertices(vs)
      #   |> Graph.add_edges(es)

      {:ok,
       %Board{dimensions: %Dimensions{width: w, height: h}, graph: nil, path_lines: path_lines}}
    end
  end

  # defp catch_undeclared_start_points(start_points, paths) do
  #   # paths = Enum.map(paths, fn {from, _to} -> from end)
  #   # IO.inspect paths
  #   undeclared_start = Enum.find(start_points, &(&1 not in paths))

  #   if undeclared_start do
  #     {:error,
  #      "start tiles must be declared in path lines, but #{format_tile(undeclared_start)} is not"}
  #   else
  #     :ok
  #   end
  # end

  # defp ensure_continuous_paths(start_points, paths) do
  #   froms = Enum.map(paths, fn {from, _to} -> from end)
  #   tos = Enum.map(paths, fn {_from, to} -> to end)

  #   broken_path = Enum.find(froms, &(&1 not in tos and &1 not in start_points))

  #   if broken_path do
  #     {:error,
  #      "paths must be continuous, but #{format_tile(broken_path)} is unreachable from the declared tiles"}
  #   else
  #     :ok
  #   end
  # end

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
  # defp catch_diagonal_lines(paths) do
  #   # If either an x or y coord isn't the same, then it
  #   # must be a diagonal.
  #   diagonal =
  #     Enum.find(paths, fn
  #       {{x, _y1}, {x, _y2}} -> false
  #       {{_x1, y}, {_x2, y}} -> false
  #       {{_x1, _y1}, {_x2, _y2}} -> true
  #     end)

  #   if diagonal do
  #     {:error,
  #      "paths must be either horizontal or vertical, but #{format_path_line(diagonal)} forms a diagonal line"}
  #   else
  #     :ok
  #   end
  # end

  # # Ensure that no path line exceeds the specified grid boundaries.
  # defp validate_boundaries({w, h}, paths) do
  #   invalid_boundary =
  #     Enum.find(paths, fn {{x1, y1}, {x2, y2}} ->
  #       x1 > w or x2 > w or y1 > h or y2 > h
  #     end)

  #   if invalid_boundary do
  #     {:error, "path line #{format_path_line(invalid_boundary)} exceeds the grid boundaries"}
  #   else
  #     :ok
  #   end
  # end

  # # Ensure that each tile only connects to one other tile, to prevent
  # # ambiguities around where players can move.
  # defp catch_ambiguous_paths(paths) do
  #   froms = Enum.map(paths, fn {from, _to} -> from end)
  #   ambiguous_path = Enum.find(froms, fn x -> Enum.count(froms, &(&1 === x)) > 1 end)

  #   if ambiguous_path do
  #     {:error,
  #      "paths must not be ambiguous, but #{format_tile(ambiguous_path)} is connected to multiple tiles"}
  #   else
  #     :ok
  #   end
  # end

  # Horizontal paths.
  defp generate_path({{x1, y}, {x2, y}}), do: for(x <- x1..x2, do: {x, y})
  # Vertical paths.
  defp generate_path({{x, y1}, {x, y2}}), do: for(y <- y1..y2, do: {x, y})

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
end
