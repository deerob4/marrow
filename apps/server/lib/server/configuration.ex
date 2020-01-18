defmodule Server.Configuration do
  @moduledoc """
  Configuration options for hosted games.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__

  @primary_key false
  schema "configuration" do
    field :is_public, :boolean, default: false
    field :allow_spectators, :boolean, default: false
    field :password, :string
    field :wait_time, :integer, default: 60
  end

  @doc """
  Validates a configuration struct against against a game model.
  """
  def changeset(%Configuration{} = struct, fields) do
    struct
    |> cast(fields, [:allow_spectators, :password, :is_public, :wait_time])
    |> validate_required([:allow_spectators, :is_public])
  end
end
