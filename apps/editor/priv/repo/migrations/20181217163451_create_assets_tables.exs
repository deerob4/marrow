defmodule Editor.Repo.Migrations.CreateAssetsTables do
  use Ecto.Migration

  def change do
    create table("images") do
      add :game_id, references("games", on_delete: :delete_all)
      add :name, :string
      add :url, :string, null: false
      timestamps()
    end

    create table("audio") do
      add :game_id, references("games", on_delete: :delete_all)
      add :name, :string
      add :url, :string, null: false
      timestamps()
    end
  end
end
