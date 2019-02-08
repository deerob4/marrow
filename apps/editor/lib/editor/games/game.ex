defmodule Editor.Games.Game do
  @moduledoc """
  An editable form of a game.
  """

  use Editor.Schema

  alias __MODULE__
  alias Language.Model
  alias Editor.Accounts.User
  alias Editor.Assets.{Audio, Image}

  schema "games" do
    field :title, :string
    field :description, :string
    field :source, :string
    field :min_players, :integer
    field :max_players, :integer
    field :is_public, :boolean
    field :cover_image, :string

    belongs_to :user, User

    has_many :images, Image
    has_many :audio, Audio

    timestamps()
  end

  def changeset(struct = %Game{}, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :source, :is_public])
    |> validate_required([:source])
    |> extract_fields()
  end

  # Some attributes of the game come from the game model, which
  # we don't store in the database. So whenever the game source
  # is changed, we want to extract the necessary fields to keep
  # the DB representation in sync.
  defp extract_fields(cset) do
    with %Ecto.Changeset{valid?: true, changes: %{source: source}} <- cset,
         {:ok, %Model{} = model} <- Language.to_game(source) do
      fields = [:title, :description, :min_players, :max_players]

      Enum.reduce(fields, cset, fn field, cset ->
        put_change(cset, field, Map.get(model, field))
      end)
    else
      _ -> cset
    end
  end
end
