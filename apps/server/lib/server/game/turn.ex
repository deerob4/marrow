defmodule Server.Game.Turn do
  @moduledoc """
  FSM process that represents an individual game turn.

  The stages of the machine are:

  1. The player rolls the dice.
  2. The piece moves around the game board.
  3.
  """

  use GenStateMachine
  alias Server.GameState

  # Client

  def start_link(data) do
    GenStateMachine.start_link(__MODULE__, {:roll, data})
  end

  def roll(pid) do
    GenStateMachine.call(pid, :roll)
  end

  # Server

  def init({game, turn_time_limit}) when is_integer(turn_time_limit) do
    {:ok, :dice, game, [{:state_timeout, turn_time_limit, :dice_timeout}]}
  end

  def handle_event({:call, from}, :roll, _state, game) do
    roll = GameState.roll_dice(game)
    {:next_state, :moving, game, [{:reply, from, roll}]}
  end

  # def handle_event({:call, from}, :moving, _state, game) do
  #   # {:next_state, :}
  # end

  def handle_event(:state_timeout, :dice_timeout, :dice, _game) do
    IO.inspect("The dice timeout occured. I will now crash")
  end
end
