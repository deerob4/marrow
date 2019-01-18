defmodule Editor.Repo.Migrations.AddKeyFieldToAssetsTables do
  use Ecto.Migration

  def change do
    alter table("images") do
      add :key, :string
    end

    alter table("audio") do
      add :key, :string
    end
  end
end
