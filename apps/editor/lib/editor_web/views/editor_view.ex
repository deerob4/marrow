defmodule EditorWeb.EditorView do
  use EditorWeb, :view

  # alias Language.Model

  # The `images` key is a list of image urls and names, and the
  # `imageTraits` key is a mapping from individual coordinates to
  # these images. Same with audio.

  def render("connected.json", %{game: game, assets: assets}) do
    %{
      images: assets.images,
      audio: assets.audio,
      cards: game.cards,
      labels: game.labels,
      editingGame: %{
        source: game.source,
        metadataId: game.id,
        compileStatus: %{type: "ok"}
      }
    }
  end

  # Data that relies on a successful compilation.
  # defp compile_data(%Model{metadata: metadata, board: board}) do
  #   %{
  #     cards: [],
  #     labelTraits: format_metadata("labels", metadata),
  #     imageTraits: format_metadata("images", metadata),
  #     board: %{dimensions: board.dimensions, paths: board.path_lines}
  #   }
  # end

  # If the board isn't compiled then we need to send over some
  # dummy data.
  # defp compile_data(:not_compiled) do
  #   %{
  #     cards: [],
  #     labels: [],
  #     labelTraits: [],
  #     imageTraits: [],
  #     board: %{
  #       paths: [%{from: %{x: 0, y: 0}, to: %{x: 5, y: 0}}],
  #       dimensions: %{width: 5, height: 5}
  #     }
  #   }
  # end

  # defp format_metadata(key, metadata) do
  #   Enum.map(metadata[key] || [], fn {coord, value} -> %{coord: coord, value: value} end)
  # end
end
