defmodule Server.MarrowError do
  @moduledoc """
  Error thrown when a runtime error occurs in the user's code.

  This module should not be confused with Elixir's built-in
  `RuntimeError`.
  """

  alias __MODULE__

  defexception message: "Marrow code runtime error", function: nil

  @doc """
  Formats the runtime error, with the function name consistently
  placed if it exists.
  """
  def format(error)

  def format(%MarrowError{message: message, function: nil}) do
    message
  end

  def format(%MarrowError{message: message, function: function}) do
    "error in `#{function}`: #{message}"
  end
end
