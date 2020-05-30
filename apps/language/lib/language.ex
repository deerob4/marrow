defmodule Language do
  @moduledoc """
  A simple DSL for expressing the rules and structure of a board
  game.

  A full language specification is available in the project
  documentation.
  """

  alias Language.{Model, Compiler, Scanner}
  alias :marrow_parser, as: Parser

  @type compile_result :: {:ok, Model.t()} | {:error, String.t()}

  @type role :: String.t()

  @type variable :: Board.tile() | role | integer | boolean | String.t()

  @doc """
  Creates a `%Language.Model` from the given source code.

  To allow for different methods of game authorship, the main
  `Marrow` system reads games in a
  """
  @spec to_game(String.t()) :: compile_result
  def to_game(source) do
    with {:ok, tokens} <- Scanner.scan_tokens(source),
         {:ok, ast} <- Parser.parse(tokens),
         {:ok, game} <- Compiler.from_ast(ast) do
      {:ok, game}
    else
      {:error, reason} when is_bitstring(reason) ->
        {:error, reason}

      {:error, {line, :marrow_parser, error_list}} ->
        error = error_list |> Enum.join()
        {:error, "Line #{line}: #{error}"}
    end
  end

  # def initialise_state(source) do
  #   with {:ok, model} <- to_game(source) do
  #     Server.GameState.initialise(model, Map.keys(model.roles))
  #   end
  # end

  def ast(source) do
    with {:ok, tokens} <- Scanner.scan_tokens(source) do
      Parser.parse(tokens)
    end
  end

  def print_tokens(source) do
    with {:ok, tokens} <- Scanner.scan_tokens(source) do
      Enum.each(tokens, &IO.inspect/1)
    end
  end
end
