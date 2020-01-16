defmodule Editor.EditorServer do
  @moduledoc """
  Responsible for holding the state of a game that is currently
  being edited.
  """

  use GenServer

  alias Editor.{EditorSupervisor, Games}

  @type get_model_return :: Language.Model.t() | :not_compiled

  # Client

  def start_link(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: via_tuple(game_id))
  end

  @doc """
  Returns the current %Language.Model{} struct for the game.
  """
  @spec get_model(integer) :: get_model_return
  def get_model(game_id) do
    GenServer.call(via_tuple(game_id), :get_model)
  end

  @doc """
  Returns the game's current source code.
  """
  @spec get_source(integer) :: String.t()
  def get_source(game_id) do
    GenServer.call(via_tuple(game_id), :get_source)
  end

  @doc """
  Replaces the game source code with the `new_source` for the
  game.
  """
  @spec update_source(integer, String.t()) :: :ok
  def update_source(game_id, new_source) do
    GenServer.cast(via_tuple(game_id), {:update_source, new_source})
  end

  @doc """
  Attemps to recompile the game using the current game source.

  If the recompilation attempt succeeds, the game model stored
  in the editor will be replaced with the updated one. In the
  event of a compilation error, the old model will still be kept
  but the error message will be returned and stored.
  """
  @spec recompile(integer) :: Language.compile_result()
  def recompile(game_id) do
    GenServer.call(via_tuple(game_id), :recompile)
  end

  @doc """
  Closes the editor for the game with the given `game_id`.

  This will flush the current game source to the database to
  ensure that it stays in sync next time the editor is opened.
  """
  @spec close_editor(integer) :: :ok
  def close_editor(game_id) do
    with pid when is_pid(pid) <- editor_pid(game_id) do
      send(pid, {:cleanup, game_id})
    end
  end

  defp editor_pid(game_id) do
    case Registry.lookup(Registry.EditorRegistry, game_id) do
      [{pid, nil}] -> pid
      _ -> :not_found
    end
  end

  defp via_tuple(uuid) do
    {:via, Registry, {Registry.EditorRegistry, uuid}}
  end

  # Server

  def init(game_id) do
    %{source: source} = Games.get_by_id!(game_id)
    {:ok, %{source: source, model: :not_compiled}}
  end

  def handle_call(:get_model, _, %{model: model} = state) do
    {:reply, model, state}
  end

  def handle_call(:get_source, _, %{source: source} = state) do
    {:reply, source, state}
  end

  def handle_call(:recompile, _, %{source: source} = state) do
    case Language.to_game(source) do
      {:ok, model} ->
        {:reply, {:ok, model}, %{state | model: model}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_cast({:update_source, new_source}, state) do
    {:noreply, %{state | source: new_source}}
  end

  def handle_info({:cleanup, game_id}, %{source: source} = state) do
    Games.update_game(game_id, %{source: source})
    DynamicSupervisor.terminate_child(EditorSupervisor, self())
    {:noreply, state}
  end
end

defmodule State do
  defstruct [
    current_player: nil,
    current_turn: nil,
    player_positions: %{},
    global_variables: %{},
    player_variables: %{}
  ]

  def move_to(state, player, coordinate) do
    put_in(state, [:player_positions, player], coordinate)
  end

  def set_global_variable(state, var, new_value) do
    put_in(state, [:global_variables, var], new_value)
  end

  def set_player_variable(state, var, player, new_value) do
    put_in(state, [:player_variables, var, player], new_value)
  end

  def increment_turn(state) do
    %{state | current_turn: state.current_turn + 1}
  end

  def events() do
    [
      %{
        name: "fall",
        parameters: ["x"],
        body: [
          {:move_to, ["x", :current_player]}
        ]
      }
    ]
  end
end
