defmodule ServerBenchmark do
  use GenServer

  @max_spawn 100_000

  @user_range 2..4

  @game_id 6

  @config %{
    allow_spectators: false,
    password: nil,
    is_public: false,
    wait_time: 30
  }

  def start_link() do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    send(self(), :start_games)
    {:ok, 0}
  end

  def handle_info(:start_games, total_spawned)
      when total_spawned >= @max_spawn do
    {:noreply, @max_spawn}
  end

  def handle_info(:start_games, total_spawned) do
    time_to_next_spawn = Enum.random(100..150)
    spawn_count = Enum.random(1..100)
    Enum.each(1..spawn_count, fn _ -> start_game() end)
    Process.send_after(self(), :start_games, time_to_next_spawn)
    IO.inspect("Games spawned: #{total_spawned + spawn_count}")
    {:noreply, total_spawned + spawn_count}
  end

  defp start_game() do
    {:ok, game_id} = Server.host_game(@game_id, @config)
    game_pid = Server.GamesSupervisor.game_pid(game_id)
    user_count = Enum.random(@user_range)

    Enum.each(1..user_count, fn _ ->
      ServerBenchmark.Client.start_link(game_pid)
    end)
  end
end
