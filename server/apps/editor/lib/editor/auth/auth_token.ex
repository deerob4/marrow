defmodule Editor.Auth.AuthToken do
  @moduledoc """
  A cryptographically signed token which is used to ensure the
  user's identity is correct.

  This schema forms the basis of the editor's authentication
  system.
  """

  use Editor.Schema
  alias Editor.Accounts.User

  schema "auth_tokens" do
    field :token, :string
    field :revoked, :boolean
    field :revoked_at, :utc_datetime
    belongs_to :user, User
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:token])
    |> validate_required([:token])
    |> unique_constraint(:token)
  end
end
