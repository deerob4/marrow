defmodule Editor.Assets.Image do
  use Editor.Schema
  alias Editor.Games.Game

  @derive {Jason.Encoder, only: [:id, :name, :url]}

  schema "images" do
    belongs_to :game, Game
    field :name, :string
    field :url, :string
    field :key, :string
    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:name, :url, :key, :game_id])
    |> validate_required([:name, :url, :game_id])
  end
end
