defmodule Editor.Repo.Migrations.MakeAuthTokenRevokedFalseByDefault do
  use Ecto.Migration

  def change do
    alter table("auth_tokens") do
      modify :revoked, :boolean, default: false
    end
  end
end
