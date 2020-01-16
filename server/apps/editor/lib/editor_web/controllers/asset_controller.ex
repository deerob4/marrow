defmodule EditorWeb.AssetController do
  use EditorWeb, :controller

  alias Editor.Assets

  plug EditorWeb.CheckAuth

  def create(conn, %{"gameId" => game_id, "fileIds" => fileIds, "files" => files, "type" => type}) do
    Enum.each(files, fn {index, upload} -> upload_file(game_id, fileIds[index], upload, type) end)
    json(conn, %{message: "received"})
  end

  defp upload_file(game_id, dummy_id, %Plug.Upload{filename: filename, path: path}, "image") do
    with {:ok, image} <- Assets.upload_image(game_id, {filename, path}) do
      EditorWeb.Endpoint.broadcast("editor:#{game_id}", "image_uploaded", %{
        id: image.id,
        dummyId: dummy_id,
        url: image.url,
        name: filename
      })
    end
  end

  defp upload_file(game_id, dummy_id, %Plug.Upload{filename: filename, path: path}, "audio") do
    with {:ok, image} <- Assets.upload_audio(game_id, {filename, path}) do
      EditorWeb.Endpoint.broadcast("editor:#{game_id}", "audio_uploaded", %{
        id: image.id,
        dummyId: dummy_id,
        url: image.url,
        name: filename
      })
    end
  end

  def update(conn, %{"id" => image_id, "type" => "image", "name" => new_name}) do
    with {:ok, image} <- Assets.rename_image(image_id, new_name) do
      render(conn, "updated.json", name: image.name)
    end
  end

  def update(conn, %{"id" => audio_id, "type" => "audio", "name" => new_name}) do
    with {:ok, audio} <- Assets.rename_audio(audio_id, new_name) do
      render(conn, "updated.json", name: audio.name)
    end
  end

  def delete(conn, %{"id" => image_id, "type" => "image"}) do
    with {:ok, _} <- Assets.delete_image(image_id) do
      render(conn, "deleted.json")
    end
  end

  def delete(conn, %{"id" => audio_id, "type" => "audio"}) do
    with {:ok, _} <- Assets.delete_audio(audio_id) do
      render(conn, "deleted.json")
    end
  end
end
