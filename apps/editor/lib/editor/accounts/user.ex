defmodule Editor.Accounts.User do
  @moduledoc """
  Schema module for an individual user of the editor.

  Users are responsible for creating and managing games.
  """

  use Editor.Schema

  alias Editor.Games.Game
  alias Editor.Auth.AuthToken

  schema "users" do
    field :name, :string
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string

    has_many :games, Game
    has_many :auth_tokens, AuthToken

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :email, :password])
  end

  def registration_changeset(struct, params \\ %{}) do
    struct
    |> changeset(params)
    |> validate_required([:name, :email, :password])
    |> validate_confirmation(:password)
    |> validate_length(:password, min: 8)
    # |> unsafe_validate_unique([:email], Editor.Repo)
    |> unique_constraint(:email)
    |> put_password_hash()
    |> cast_assoc(:games)
  end

  defp put_password_hash(cset) do
    case cset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        cset
        |> put_change(:password_hash, Comeonin.Argon2.hashpwsalt(password))
        |> delete_change(:password)

      _ ->
        cset
    end
  end
end
