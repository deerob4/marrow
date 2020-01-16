defmodule Language.Model.GlobalVariable do
  @moduledoc """
  Defines a variable in the game, which can be used to hold a
  value that changes over time.
  """

  alias __MODULE__

  defimpl Jason.Encoder do
    def encode(variable, opts) do
      variable
      |> Map.take([:name, :value])
      |> Map.put(:type, "global")
      |> Jason.Encode.map(opts)
    end
  end

  defstruct [:name, :value]

  @type t :: %__MODULE__{name: String.t(), value: Language.variable()}

  @doc """
  Replaces the value of `var` with `new_value`.

  # Examples

      iex> alias Language.Model.GlobalVariable, as: GV
      ...> GV.update_value(%GV{name: "score", value: 10}, 20)
      %GV{name: "score", value: 20}

  """
  @spec update_value(t, Language.variable()) :: t
  def update_value(%GlobalVariable{} = var, new_value) do
    %{var | value: new_value}
  end
end
