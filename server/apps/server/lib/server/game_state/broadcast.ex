defmodule Server.GameState.Broadcast do
  @moduledoc """
  Represents a broadcast from one player to a group of others.
  """

  defstruct [:id, :message, :send_to]

  @type t :: %__MODULE__{id: String.t(), message: String.t(), send_to: [Language.role()]}

  @doc """
  Constructs a unique `%Server.GameState.Broadcast{}` struct with
  the given `message`, to be sent to the roles listed in `send_to`.
  """
  @spec new(String.t(), [Language.role()]) :: t
  def new(message, send_to) do
    %__MODULE__{
      id: UUID.uuid4(),
      message: message,
      send_to: send_to
    }
  end
end
