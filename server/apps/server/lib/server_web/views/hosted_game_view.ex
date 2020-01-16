defmodule ServerWeb.HostedGameView do
  use ServerWeb, :view
  alias Server.Configuration

  def render("created.json", %{id: id}) do
    %{status: "created", data: %{id: id}}
  end

  def render("deleted.json", _) do
    %{status: "deleted"}
  end

  def render("index.json", %{games: games}) do
    games = Enum.map(games, &render("show.json", game: &1))
    games |> Jason.encode!() |> Phoenix.HTML.raw()
  end

  def render("show.json", %{game: game}) do
    %{
      id: game.id,
      title: game.title,
      description: get_description(game.description),
      minPlayers: game.min_players,
      maxPlayers: game.max_players,
      author: game.user.name
    }
  end

  defp get_description(""), do: nil
  defp get_description(desc), do: desc

  @doc """
  Returns the combined description and player count of the game.
  """
  @spec description(Editor.Games.Game.t()) :: String.t()
  def description(game), do: "#{do_description(game)} For #{player_count(game)}."

  defp do_description(%{description: nil}), do: "No description available."
  defp do_description(%{description: desc}), do: desc

  defp player_count(%{min_players: 1, max_players: 1}), do: "1 player"
  defp player_count(%{min_players: same, max_players: same}), do: "#{same} players"
  defp player_count(%{min_players: min, max_players: max}), do: "#{min} - #{max} players"

end
