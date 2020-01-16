defmodule Language.Model.Dice do
  @moduledoc """
  A struct and associated functions for working with dice.

  Dice are a fundamental part of the board games created
  using Marrow. They are the main method by which players
  move around the board, so a range of options are
  available.

  Marrow allows games to use a wide combination of dice
  can use any combination of dice - one six sided die, as
  is traditional.

  The `%Marrow.Game.Dice{}` struct contains two fields:

    * `sides` is a list where each element represents the
      number of sides a die has. For a single six sided
      die, `[6]` would be used; for two 12 sided dice
      [12, 12]; and so on.

    * `reduce_by` specifies how all the rolled values
      should be reduced to produce a single value. The
      available values are `:sum`, `:subtract`, and
      `:multiply`. `:sum` is the default value.

  A die may have up to 100 sides, and a game may use up to
  20 dice.
  """

  alias __MODULE__

  defstruct sides: [6], reduce_by: :sum

  @type reduce_by :: :sum | :subtract | :multiply

  @type t :: %__MODULE__{
          sides: list(pos_integer),
          reduce_by: reduce_by
        }

  # The max number of dice allowed in a game.
  @max_dice 20

  # The max number of sides a die can have.
  @max_die_sides 100

  defmodule Roll do
    @moduledoc """
    Represents a roll of the dice on a particular turn.
    """

    defstruct [:turn, :rolled]
  end

  @doc """
  Returns whether or not `dice` is valid.

  See the module documentation for a definition of what
  constitutes a valid `%Marrow.Game.Dice{}` struct.
  """
  @spec valid?(t) :: boolean

  def valid?(%Dice{sides: sides, reduce_by: reduce_by})
      when is_list(sides) and length(sides) <= @max_dice and
             reduce_by in [:sum, :subtract, :multiply] do
    Enum.all?(sides, &(&1 <= @max_die_sides))
  end

  def valid?(%Dice{}), do: false

  @doc """

  """
  @spec add_die(t, integer) :: t
  def add_die(%Dice{sides: sides} = dice, die) do
    %Dice{dice | sides: [die | sides]}
  end

  @doc """
  Rolls `dice` and returns the rolled value.

  For every value in `sides`, a random number is chosen
  between `1` and that value. This list of values is then
  applied to `reduce_by` to produce the final roll.

  This function returns a tuple in the format
  `{final_roll, rolls}`, where `rolls`  is a list
  containing the value that each die rolled.
  """
  @spec roll(t) :: integer
  def roll(%Dice{sides: sides, reduce_by: reduce_by}) do
    rolls = Enum.map(sides, &Enum.random(1..&1))
    Enum.reduce(rolls, arith_fun(reduce_by))
  end

  @spec arith_fun(reduce_by) :: (pos_integer, pos_integer -> String.t())
  defp arith_fun(:sum), do: &+/2
  defp arith_fun(:multiply), do: &*/2
  defp arith_fun(:subtract), do: &-/2
end
