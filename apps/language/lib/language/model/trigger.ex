defmodule Language.Model.Trigger do
  @moduledoc """
  A series of events that are conditionally run at the beginning
  of every turn.
  """

  alias __MODULE__
  alias Language.Compiler

  defstruct condition: nil, events: []

  @type t :: %__MODULE__{condition: Compiler.ast(), events: [Compiler.ast()]}

  @doc """
  Creates a new trigger with the given `events` that is run when
  `condition` is true.
  """
  @spec new(Compiler.ast(), [Compiler.ast()]) :: t
  def new(condition, events) do
    %Trigger{condition: condition, events: events}
  end
end
