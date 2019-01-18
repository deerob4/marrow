defmodule Language.Model.Event do
  @moduledoc """
  A named custom procedure that groups together a list of
  builtin commands.
  """

  alias __MODULE__
  alias Language.Compiler

  defstruct args: [], body: []

  @type t :: %__MODULE__{args: [String.t()], body: [Compiler.ast()]}

  @doc """
  Creates a new event with the given `args` list and `body`.
  """
  @spec new([String.t()], [Compiler.ast()]) :: t
  def new(args, body) do
    %Event{args: args, body: body}
  end
end
