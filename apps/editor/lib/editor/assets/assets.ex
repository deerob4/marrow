defmodule Editor.Assets do
  @moduledoc """
  Context module for managing game assets.

  These are external resources that can be attached to a game.
  They currently include images, which can be associated with an
  individual board tile; and audio, which can be programmed to
  play on a certain event.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias Editor.Repo
  alias Editor.Games.Game
  alias Editor.Assets.{Audio, Image, Uploader}
  alias Language.Model

  @type asset :: :image | :audio

  @type asset_map :: %{optional(:image) => [Image.t()], optional(:audio) => [Audio.t()]}

  @type file_details :: {filename :: String.t(), file_path :: String.t()}

  @doc """
  Uploads a new image file and associates it with the game with
  the given `game_id`.

  The `file_path` string must be a location on disk, most likely
  somewhere in the `tmp` directory.

  Returns `{:ok, image}` if successful, otherwise `{:error, reason}`.
  """
  @spec upload_image(integer, file_details) :: {:ok, Image.t()} | {:error, String.t()}
  def upload_image(game_id, {filename, file_path}) do
    with {:ok, filename, key, url} <- Uploader.upload(:image, {filename, file_path}) do
      cset = Image.changeset(%Image{}, %{name: filename, url: url, key: key, game_id: game_id})
      Repo.insert(cset)
    end
  end

  @doc """
  Renames the given image to `new_name`.

  Returns `{:ok, image}` if successful, otherwise `{:error, reason}`.
  """
  @spec rename_image(integer, String.t()) :: {:ok, Image.t()} | {:error, String.t()}
  def rename_image(image_id, new_name) do
    image = Repo.get(Image, image_id)
    cset = Image.changeset(image, %{name: new_name})
    Repo.update(cset)
  end

  @doc """
  Deletes the image with the given `image_id`.

  Returns `{:ok, image}` if successful, otherwise `{:error, reason}`.
  """
  @spec delete_image(integer) :: {:ok, Image.t()} | {:error, String.t()}
  def delete_image(image_id) do
    image = Repo.get!(Image, image_id)

    Multi.new()
    |> Multi.run(:s3, fn _, _ -> Uploader.delete(:image, image.key) end)
    |> Multi.delete(:delete, image)
    |> Repo.transaction()
  end

  @doc """
  Uploads a new audio file and associates it with the game with
  the given `game_id`.

  The `file_path` string must be a location on disk, most likely
  somewhere in the `tmp` directory.

  Returns `{:ok, audio}` if successful, otherwise `{:error, reason}`.
  """
  @spec upload_audio(integer, file_details) :: {:ok, Audio.t()} | {:error, String.t()}
  def upload_audio(game_id, {filename, file_path}) do
    with {:ok, filename, key, url} <- Uploader.upload(:audio, {filename, file_path}) do
      cset = Audio.changeset(%Audio{}, %{name: filename, url: url, key: key, game_id: game_id})
      Repo.insert(cset)
    end
  end

  @doc """
  Renames the given audio to `new_name`.

  Returns `{:ok, audio}` if successful, otherwise `{:error, reason}`.
  """
  @spec rename_audio(integer, String.t()) :: {:ok, Audio.t()} | {:error, String.t()}
  def rename_audio(audio_id, new_name) do
    audio = Repo.get(Audio, audio_id)
    cset = Audio.changeset(audio, %{name: new_name})
    Repo.update(cset)
  end

  @doc """
  Deletes the audio with the given `audio_id`.

  Returns `{:ok, audio}` if successful, otherwise `{:error, reason}`.
  """
  @spec delete_audio(integer) :: {:ok, Audio.t()} | {:error, String.t()}
  def delete_audio(audio_id) do
    audio = Repo.get(Audio, audio_id)
    Repo.delete(audio)
  end

  @doc """
  Preloads the given `assets` in the `game` struct.
  """
  @spec preload_assets(Game.t(), [asset]) :: Game.t()
  def preload_assets(game, assets \\ []) do
    assets = if assets === [], do: [:images, :audio], else: assets
    Repo.preload(game, assets)
  end

  @doc """
  Returns the image called `name` in the given game.
  """
  @spec get_image_by_name(String.t(), integer) :: Image.t() | nil
  def get_image_by_name(name, game_id) do
    Repo.get_by(Image, name: name, game_id: game_id)
  end

  @doc """
  Replaces the image names used in the image metadata with the
  actual URLs.
  """
  @spec replace_image_metadata(Model.t(), integer) :: Model.t()
  def replace_image_metadata(
        %Model{metadata: %{"images" => game_images} = metadata} = model,
        game_id
      ) do
    saved_images = get_saved_images(game_id)
    game_images = replace_metadata(game_images, saved_images)
    %{model | metadata: %{metadata | "images" => game_images}}
  end

  def replace_image_metadata(%Model{} = model, _game_id) do
    model
  end

  defp get_saved_images(game_id) do
    from(i in Image, where: i.game_id == ^game_id, select: %{i.name => i.url})
    |> Repo.all()
    |> Enum.reduce(&Map.merge/2)
  end

  defp replace_metadata(game_images, saved_images) do
    Map.new(game_images, fn {tile, name} ->
      if url = saved_images[name] do
        {tile, url}
      else
        {tile, name}
      end
    end)
  end
end
