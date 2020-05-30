defmodule Language.Docs.Types do
  @moduledoc """
  Helper functions for expressing types.
  """

  defmodule Scalar do
    defstruct [:type]
  end

  defmodule Identifier do
    defstruct [:value]
  end

  defmodule List do
    defstruct [:type]
  end

  defmodule Pair do
    defstruct [:first, :second]
  end

  defmodule Or do
    defstruct [:types]
  end
end
