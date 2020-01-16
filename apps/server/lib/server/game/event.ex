defmodule Server.Game.Event do
  @moduledoc """
  Defines an event in the game.

  Every move and action taken in the game results in an
  `%Event{}` struct, so that other players can be informed of
  what is going on.
  """

  alias __MODULE__

  defimpl Jason.Encoder do
    alias Server.Game.Event

    def encode(%{player: player, turn: turn, event: type} = event, opts) do
      Jason.Encode.map(
        %{
          player: player,
          turn: turn,
          text: Event.Formatter.format_event(event),
          type: event_type(type)
        },
        opts
      )
    end

    defp event_type(%{__struct__: Event.JoinEvent}), do: "join"
    defp event_type(%{__struct__: Event.LeaveEvent}), do: "leave"
    defp event_type(_), do: "normal"
  end

  defmodule JoinEvent, do: defstruct []

  defmodule LeaveEvent, do: defstruct []

  defmodule MissTurnEvent, do: defstruct []

  defmodule RollEvent, do: defstruct [:rolled]

  defmodule MovementEvent, do: defstruct [:spaces_moved, :prev_tile, :new_tile]

  defmodule MessageEvent, do: defstruct [:from, :body]

  defmodule GlobalVariableEvent, do: defstruct [:variable, :new_value]

  defmodule PlayerVariableEvent, do: defstruct [:variable, :new_value]

  defmodule CardEvent, do: defstruct [:player, :card, :choice]

  defstruct [:turn, :player, :event]

  @type event ::
          JoinEvent.t()
          | LeaveEvent.t()
          | RollEvent.t()
          | MovementEvent.t()
          | MessageEvent.t()
          | CardEvent.t()
          | GlobalVariableEvent.t()
          | PlayerVariableEvent.t()
          | MissTurnEvent.t()

  @type t :: %__MODULE__{turn: pos_integer, player: Language.role(), event: event}
end
