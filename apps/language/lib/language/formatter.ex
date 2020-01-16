defmodule Language.Formatter do
  @moduledoc """
  Formats expressions to and from the Elixir and MarrowLang
  syntax.

  The main differences between the two are that underscores are
  not allowed in MarrowLang, and are replaced with dashes. Dashes
  are unwieldy in Elixir atoms, however, and so are replaced with
  underscores.
  """

  @doc """
  Formats a card event list into a callable AST syntax.

  Card events are parsed as straight lists in the form

  """
  def format_events([single_with_no_args]), do: [{single_with_no_args, []}]
  def format_events(otherwise), do: [otherwise]

  @doc """
  Formats a standard identifier into `MarrowLang` form.

  ## Examples

      iex> Language.Formatter.format_identifier("hello_world")
      "hello-world"

      iex> Language.Formatter.format_identifier(123)
      "123"

  """
  def format_identifier(identifier)

  def format_identifier({x, y}) when is_integer(x) and is_integer(y),
    do: "(#{x} #{y})"

  def format_identifier({:variable, {player, var_name}}),
    do: "#{player}->#{var_name}"

  def format_identifier(identifier) when is_bitstring(identifier),
    do: String.replace(identifier, "_", "-")

  def format_identifier(identifier),
    do: identifier |> inspect() |> format_identifier()

  @doc """
  Returns the name of the given `number` in words if it is less
  than 10, otherwise returns the number unchanged.

  ## Examples

      iex> Language.Formatter.format_number(0)
      "zero"

      iex> Language.Formatter.format_number(4)
      "four"

      iex> Language.Formatter.format_number(12)
      12

  """
  @spec format_number(integer) :: String.t() | number
  def format_number(number)
  def format_number(0), do: "zero"
  def format_number(1), do: "one"
  def format_number(2), do: "two"
  def format_number(3), do: "three"
  def format_number(4), do: "four"
  def format_number(5), do: "five"
  def format_number(6), do: "six"
  def format_number(7), do: "seven"
  def format_number(8), do: "eight"
  def format_number(9), do: "nine"
  def format_number(10), do: "ten"
  def format_number(larger), do: larger

  @doc """
  Takes a numeric quantity and a conjunctive and returns the
  correct version based on the quantity.

  ## Examples

      iex> Language.Formatter.format_plural(1, "was", "were")
      "was"

      iex> Language.Formatter.format_plural(8, "was", "were")
      "were"

  """
  @spec format_plural(integer, String.t(), String.t()) :: String.t()
  def format_plural(quantity, singular, plural)
  def format_plural(1, singular, _plural), do: singular
  def format_plural(_, _singular, plural), do: plural

  @doc """
  Formats a Yecc error message into a more human-friendly one.

  The Yecc parser included with the ERTS produces error messages
  that expose that the language was written in a BEAM language.
  This function strips out those identifiers, and adds syntax
  highlighting to make it more consistent with error messages
  returned by other parts of the compiler.

  ## Examples

      iex> error = "Line 11: syntax error before: <<\"paith\">>."
      ...> Language.Formatter.format_error(error)
      "Line 11: syntax error before: `paith`"

  """
  @spec format_error(String.t()) :: String.t()
  def format_error(error) do
    error
    |> String.replace(~r{(<<|>>)}, "")
    |> String.replace(~s{""}, "`")
  end

  @doc """
  Formats a fragment of parsed AST into valid MarrowLang code.

  ## Examples

      iex> Language.Formatter.format_ast({:+, [10, 20]})
      "(+ 10 20)"

      iex> Language.Formatter.format_ast({:+, [10, 20]})
      "(+ 10 20)"
  """
  @spec format_ast(Language.Compiler.ast()) :: String.t()
  def format_ast(ast) do
    ast
  end
end
