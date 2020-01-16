defmodule ServerBenchmark.Client do
  use GenServer

  @messages [:join_game, :leave_game, :roll_dice]

  def start_link(game_pid) do
    GenServer.start_link(__MODULE__, game_pid)
  end

  def init(game_pid) do
    max_messages = Enum.random(3..10)
    send(self(), :talk_to_server)
    {:ok, {game_pid, max_messages, 0}}
  end


  def handle_info(:talk_to_server, {game_pid, max_messages, count}) do
    next_message = Enum.random(1000..5000)
    Process.send_after(self(), :talk_to_server, next_message)
    send(game_pid, Enum.random(@messages))
    {:noreply, {game_pid, max_messages, count + 1}}
  end
end
