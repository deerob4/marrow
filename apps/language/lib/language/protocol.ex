defmodule Language.Protocol do
  @moduledoc """
  Defines the callbacks that the compiler and interpreter should
  implement.
  """

  @type state :: any

  @type role :: String.t()

  @type tile :: {integer(), integer()}

  @type type :: String.t() | integer() | boolean() | tile() | role() | identifier()

  defmacro __using__(_) do
    quote do
      Module.register_attribute(__MODULE__, :marrowdoc, accumulate: true)
    end
  end
end
