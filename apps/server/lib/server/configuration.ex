defmodule Server.Configuration do
  @moduledoc """
  Configuration options for hosted games.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__

  @primary_key false
  schema "configuration" do
    field :is_public, :boolean
    field :allow_spectators, :boolean
    field :password, :string
  end

  @doc """
  Validates a configuration struct against against a game model.
  """
  def changeset(%Configuration{} = struct, fields) do
    struct
    |> cast(fields, [:allow_spectators, :password, :is_public])
    |> validate_required([:allow_spectators, :is_public])
  end
end
