defmodule Editor.Games do
  @moduledoc """
  Context module responsible for managing games.

  All games in the wider Marrow system start out here. They are
  stored in the database as the.
  """

  import Ecto.Query

  alias Editor.Games.Game
  alias Editor.{Assets, EditorServer, Repo}

  @type editor_data :: {game :: Game.t(), model :: Language.GameModel.t(), source :: String.t()}

  @default_source """
  (defgame "New Game"
    (description "A fun game that lots of people can play.")

    (players
      (min-players 2)
      (max-players 3)
      (roles a b c)
      (start-tile (0 0)))

    (board (5 5)
      (path (0 0) (4 0))
      (path (4 0) (4 4))
      (path (4 4) (0 4))
      (path (0 4) (0 0))))
  """

  @doc """
  Creates a new game for the given user.
  """
  def create_game(user_id) do
    cset =
      Game.changeset(%Game{}, %{
        user_id: user_id,
        is_public: true,
        source: @default_source
      })

    Repo.insert(cset)
  end

  @doc """
  Updates the game with the new params.
  """
  def update_game(game_id, game_params) do
    game = Repo.get!(Game, game_id)
    cset = Game.changeset(game, game_params)
    Repo.update(cset)
  end

  @doc """
  Deletes the game with the given `game_id` if it exists.
  """
  def delete_game(game_id) do
    game = Repo.get!(Game, game_id)
    Repo.delete(game)
  end

  @doc """
  Returns a list of all the games that are set to public
  and can be played.
  """
  def list_public_games() do
    Repo.all(from g in Game, where: [is_public: true], preload: [:user])
  end

  @doc """
  Returns a list of all the games belonging to the user with the
  given `user_id`.
  """
  def list_games_for_user(user_id) do
    Repo.all(from g in Game, where: [user_id: ^user_id])
  end

  @doc """
  Returns the game with the given `game_id`.

  Raises if the game doesn't exists.
  """
  def get_by_id!(game_id) do
    Repo.get!(Game, game_id)
  end

  @doc """
  Toggles the `is_public` property of the game with the given
  `game_id` and returns the new value.
  """
  def toggle_visibility(game_id) do
    %Game{is_public: is_public} = game = Repo.get(Game, game_id)
    cset = Game.changeset(game, %{is_public: not is_public})
    %{is_public: is_public} = Repo.update!(cset)
    is_public
  end

  @doc """
  Loads the user's games and places them inside the user struct.

  This function only loads the title and cover image of the
  game. Additional data, such as the source, should be retrieved
  by connecting to an editor process.
  """
  def load_games_for_user(user) do
    Repo.preload(user, :games)
  end

  @doc """
  Returns the combined set of information about the game
  necessary for display in the editor.
  """
  @spec load_editor_data(integer) :: {Game.t(), EditorServer.get_model_return(), String.t()}
  def load_editor_data(game_id) do
    game = game_id |> get_by_id!() |> Assets.preload_assets()
    model = EditorServer.get_model(game_id)
    source = EditorServer.get_source(game_id)

    {game, model, source}
  end
end
