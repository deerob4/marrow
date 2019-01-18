defmodule Editor.Repo.Migrations.CreateAuthTokensTable do
  use Ecto.Migration

  def change do
    create table(:auth_tokens) do
      add :token, :string
      add :revoked, :boolean
      add :revoked_at, :utc_datetime
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end
  end
end
