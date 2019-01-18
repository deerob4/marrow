defmodule EditorWeb.EditorChannel do
  use EditorWeb, :channel

  alias Editor.EditorServer
  alias Editor.EditorSupervisor
  alias Editor.Games
  alias Language.Model

  def join("editor:" <> game_id, _params, socket) do
    socket = socket |> assign(:game_id, String.to_integer(game_id))
    send(self(), :setup)
    {:ok, socket}
  end

  def handle_in("recompile", _params, socket) do
    case EditorServer.recompile(socket.assigns.game_id) do
      {:ok, model} ->
        save_source(socket.assigns.game_id)
        {:reply, {:ok, %{game: format_model(model)}}, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: reason}}, socket}
    end
  end

  def handle_in("edit_source", %{"source" => new_source}, socket) do
    :ok = EditorServer.update_source(socket.assigns.game_id, new_source)
    broadcast_from(socket, "edit_source", %{newSource: new_source})
    {:noreply, socket}
  end

  def handle_info(:setup, socket) do
    game_id = socket.assigns.game_id

    DynamicSupervisor.start_child(EditorSupervisor, {EditorServer, game_id})

    {game, model, source} = Games.load_editor_data(game_id)

    # Some data is available whether the game has been compiled or not.
    available_data = %{
      editingGame: %{
        source: source,
        metadataId: socket.assigns.game_id,
        compileStatus: %{type: "ok"}
      },
      images: game.images,
      audio: game.audio
    }

    # Others are dependent on a valid game model.
    derived = derived_data(model)

    push(socket, "connected", %{data: Map.merge(available_data, derived)})

    {:noreply, socket}
  end

  defp save_source(game_id) do
    source = EditorServer.get_source(game_id)
    Games.update_game(game_id, %{source: source})
  end

  def terminate(_, socket) do
    save_source(socket.assigns.game_id)
  end

  defp format_model(game_model) do
    %{
      board: %{
        dimensions: game_model.board.dimensions,
        paths: game_model.board.path_lines
      },
      images: format_metadata("images", game_model.metadata),
      labels: format_metadata("labels", game_model.metadata),
      audio: format_metadata("audio", game_model.metadata)
    }
  end

  defp format_metadata(key, metadata) do
    Enum.map(metadata[key] || [], fn {coord, value} -> %{coord: coord, value: value} end)
  end

  defp derived_data(%Model{metadata: metadata, board: board}) do
    %{
      cards: [],
      labelTraits: format_metadata("labels", metadata),
      imageTraits: format_metadata("images", metadata),
      board: %{dimensions: board.dimensions, paths: board.path_lines}
    }
  end

  defp derived_data(:not_compiled) do
    %{
      board: %{
        paths: [%{from: %{x: 0, y: 0}, to: %{x: 5, y: 0}}],
        dimensions: %{width: 10, height: 10}
      },
      cards: [],
      labels: [],
      labelTraits: [],
      imageTraits: []
    }
  end
end
