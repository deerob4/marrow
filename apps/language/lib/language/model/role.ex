defmodule Language.Model.Role do
  @moduledoc """
  An individual player in the game.

  Roles represent pieces on the game board. Every player must
  associate themselves with a role, and there can only be one of
  each type of role on the board.
  """

  alias Language.Model.Board.Tile

  defimpl Jason.Encoder do
    def encode(%{name: name, repr: {type, value}}, opts) do
      %{name: name, repr: %{type: type, value: value}}
      |> Jason.Encode.map(opts)
    end
  end

  defstruct [:name, :repr, :start_on]

  @type repr :: {:colour, String.t()} | {:image, String.t()}

  @type t :: %__MODULE__{name: String.t(), repr: repr, start_on: Tile.t() | nil}
end
