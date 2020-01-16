defmodule Language.Model.PlayerVariable do
  @moduledoc """
  Defines a player variable. This is a type of variable where
  each player in the game has their own value, such as score.
  """

  alias __MODULE__

  defimpl Jason.Encoder do
    def encode(%{name: name, values: values}, opts) do
      variable = %{
        name: name,
        type: "player",
        values: Enum.map(values, &encode_value/1)
      }

      Jason.Encode.map(variable, opts)
    end

    defp encode_value({role, value}), do: %{role: role, value: value}
  end

  defstruct name: nil, values: %{}

  @type t :: %__MODULE__{name: String.t(), values: %{Language.role() => Language.variable()}}

  @doc """
  Replaces the value for `role` with `new_value`.
  """
  def update_value(%PlayerVariable{values: values} = var, role, new_value) do
    %{var | values: Map.put(values, role, new_value)}
  end
end
