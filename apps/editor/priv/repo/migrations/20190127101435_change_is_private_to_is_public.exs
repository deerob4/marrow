defmodule Editor.Repo.Migrations.ChangeIsPrivateToIsPublic do
  use Ecto.Migration

  def change do
    rename table("games"), :is_private, to: :is_public
  end
end
