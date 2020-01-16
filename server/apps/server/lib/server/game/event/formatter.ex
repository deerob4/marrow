defmodule Server.Game.Event.Formatter do
  @moduledoc """
  Module responsible for formatting events.
  """

  import Language.Formatter, only: [format_identifier: 1]

  alias Server.Game.Event

  alias Event.{
    JoinEvent,
    LeaveEvent,
    MessageEvent,
    RollEvent,
    MovementEvent,
    CardEvent,
    MissTurnEvent,
    GlobalVariableEvent,
    PlayerVariableEvent
  }

  @doc """
  Returns a string formatted version of the event.
  """
  @spec format_event(Event.t()) :: String.t()
  def format_event(event)

  def format_event(%{player: player} = event) do
    do_format_event(%{event | player: player})
  end

  defp do_format_event(%{event: %JoinEvent{}}) do
    "has joined the game"
  end

  defp do_format_event(%{event: %LeaveEvent{}}) do
    "has left the game"
  end

  defp do_format_event(%{event: %MessageEvent{body: body}}) do
    "sent a message: #{body}"
  end

  defp do_format_event(%{event: %RollEvent{rolled: rolled}}) do
    "rolled a #{rolled}"
  end

  defp do_format_event(%{event: %MovementEvent{prev_tile: prev, new_tile: new}}) do
    "moved from `#{inspect(prev)}` to `#{inspect(new)}`"
  end

  defp do_format_event(%{event: %MissTurnEvent{}}) do
    "missed their turn"
  end

  defp do_format_event(%{event: %GlobalVariableEvent{variable: var, new_value: value}}) do
    "`#{format_identifier(var)}` changed to #{value}"
  end

  # Player name is encoded in the rest of the event.
  defp do_format_event(%{event: %PlayerVariableEvent{variable: var, new_value: value}}) do
    "var `#{format_identifier(var)}` changed to #{value}"
  end

  defp do_format_event(%{event: %CardEvent{}}) do
    "drew a card"
  end
end
