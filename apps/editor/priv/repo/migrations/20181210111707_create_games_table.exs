defmodule Editor.Repo.Migrations.CreateGamesTable do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :title, :string, null: false
      add :description, :string
      add :source, :text
      add :min_players, :integer
      add :max_players, :integer
      add :is_private, :boolean, default: true
      add :cover_image, :string
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end
  end
end
