defmodule Server.GameState.MissedTurns do
  @moduledoc """
  Specifies a
  """

  @typedoc """
  Does something cool.
  """
  @type t :: %__MODULE__{duration: integer, set_on: integer}

  defstruct [:duration, :set_on]

  @spec can_move?(t, integer) :: boolean
  def can_move?(%__MODULE__{duration: duration, set_on: set_on}, current_turn) do
    current_turn - set_on > duration
  end
end
