defmodule Editor.Schema do
  @moduledoc """
  Defines common imports and aliases for schema modules.
  """

  defmacro __using__(_) do
    quote do
      use Ecto.Schema

      import Ecto.Changeset
      import Ecto.Query

      alias Ecto.Changeset
    end
  end
end
