defmodule Language.Scanner do
  @moduledoc """
  Scans an input and converts it into tokens.
  """

  @typedoc """
  The different categories that MarrowLang lexemes can fall
  into.
  """
  @type lexeme_category ::
          :string
          | :integer
          | :identifier
          | :operator
          | :builtin
          | :boolean

  @typedoc """
  Defines how the MarrowLang types are represented as
  Elixir types.
  """
  @type lexeme_type :: String.t() | non_neg_integer | boolean | atom

  @typep line_number :: pos_integer

  @type token :: {atom, line_number} | {lexeme_category, lexeme_type, pos_integer}

  @operators ["+", "-", "*", "/", "%", ">", "<", "="]

  @reserved_identifiers [
    "true",
    "false",
    # Blocks
    "description",
    "dice",
    "callbacks",
    "definitions",
    "variables",
    "players",
    # Functions
    "and",
    "or",
    "not",
    "player-tile",
    "min-players",
    "max-players",
    "minimum",
    "maximum",
    "min",
    "max",
    "start-tile",
    "start-order",
    "metadata",
    "tile",
    "roles",
    "concat",
    "broadcast",
    "broadcast-to",
    "increment!",
    "decrement!",
    "set!",
    "win",
    "lose",
    "move-to",
    "max-turns",
    "turn-time-limit",
    "choose-random",
    "rand-int",
    # Variables
    "?current-player",
    "?current-tile",
    "?current-turn",
    "?player-count",
    "?board-height",
    "?board-width",
    # Callbacks
    "handle-win",
    "handle-lose",
    "handle-timeup",
    # Cards
    "cards",
    "do",
    "stack",
    "body",
    "actions",
    "choose-card"
  ]

  @custom_syntax [
    "defgame",
    "events",
    "triggers",
    "board",
    "path",
    "global",
    "player",
    "if"
  ]

  def scan_tokens("") do
    {:error, "empty inputs are invalid"}
  end

  def scan_tokens(string) do
    case String.codepoints(string) do
      ["(" | _rest] = tokens ->
        do_lex(tokens, [], 1)

      [_ | _rest] ->
        build_error(1, "Missing parentheses at start of input.")
    end
  end

  @spec do_lex([String.t()], [tuple], integer) :: {:ok, [tuple]} | {:error, String.t()}
  defp do_lex([], lexemes, _), do: {:ok, Enum.reverse(lexemes)}

  defp do_lex(tokens, lexemes, line) do
    case extract_token(tokens, line) do
      {:ignore, line, rest} ->
        do_lex(rest, lexemes, line)

      {{:error, reason}, line, _rest} ->
        build_error(line, reason)

      {{_, line, _} = token, rest} ->
        do_lex(rest, [token | lexemes], line)

      {{_, line} = token, rest} ->
        do_lex(rest, [token | lexemes], line)
    end
  end

  # Parentheses

  defp extract_token(["(" | rest], line),
    do: {{:"(", line}, rest}

  defp extract_token([")" | rest], line),
    do: {{:")", line}, rest}

  # Integers

  defp extract_token(["-", <<x>> = s | rest], line) when x in ?0..?9,
    do: extract_number(rest, line, [s, "-"])

  defp extract_token([<<x>> = s | rest], line) when x in ?0..?9,
    do: extract_number(rest, line, [s])

  # Operators

  defp extract_token([x, y | rest], line) when {x, y} in [{"<", "="}, {">", "="}],
    do: {{:operator, line, String.to_atom(x <> y)}, rest}

  defp extract_token([x | rest], line) when x in @operators,
    do: {{:operator, line, String.to_atom(x)}, rest}

  defp extract_token([";" | rest], line), do: extract_comment(rest, line)

  # Blank space

  defp extract_token(["\t" | rest], line), do: {:ignore, line, rest}
  defp extract_token([" " | rest], line), do: {:ignore, line, rest}
  defp extract_token(["\n" | rest], line), do: {:ignore, line + 1, rest}

  defp extract_token(["\"" | rest], line), do: extract_string(rest, line, "")

  defp extract_token([<<x>> = s | rest], line) when x in ?a..?z or s === "?",
    do: extract_identifier(rest, line, s)

  defp extract_token([char | rest], line),
    do: unexpected_character(char, line, rest)

  # Comments

  defp extract_comment([], line), do: {:ignore, line, []}
  defp extract_comment(["\n" | rest], line), do: {:ignore, line, rest}
  defp extract_comment([_ | rest], line), do: extract_comment(rest, line)

  # Strings

  defp extract_string([], line, _acc),
    do: {{:error, "unterminated string"}, line, []}

  defp extract_string(["\"" | rest], line, acc),
    do: {{:string, line, acc}, rest}

  defp extract_string(["\n" | rest], line, acc),
    do: extract_string(rest, line + 1, acc)

  defp extract_string([char | rest], line, acc),
    do: extract_string(rest, line, acc <> char)

  # Numbers

  defp extract_number([], line, acc), do: form_number(acc, line, [])

  defp extract_number([<<x>> = s | rest], line, acc) when x in ?0..?9,
    do: extract_number(rest, line, [s | acc])

  defp extract_number([x | rest], line, acc) when x in [" ", ")"] do
    rest = if x === ")", do: [")" | rest], else: rest
    form_number(acc, line, rest)
  end

  defp extract_number([char | rest], line, _acc),
    do: unexpected_character(char, line, rest)

  defp form_number(acc, line, rest) do
    number = acc |> Enum.reverse() |> Enum.join() |> String.to_integer()
    {{:integer, line, number}, rest}
  end

  # Identifiers

  defp extract_identifier([<<x>> = s | rest], line, acc)
       when x in ?a..?z or s === "-",
       do: extract_identifier(rest, line, acc <> s)

  defp extract_identifier([last, ooh | rest], line, _acc)
       when last in ["!", "?"] and ooh not in [" ", ")"],
       do: unexpected_character(ooh, line, rest)

  defp extract_identifier([last | rest], line, acc) when last in [" ", ")", "\n", "!", "?"] do
    acc = if last in ["!", "?"], do: acc <> last, else: acc
    rest = if last === ")", do: [last | rest], else: rest
    line = if last === "\n", do: line + 1, else: line

    case get_identifier_token(acc) do
      {:identifier, id} ->
        {{:identifier, line, id}, rest}

      {:builtin, id} ->
        {{:builtin, line, id}, rest}

      {:custom_syntax, id} ->
        {{id, line}, rest}
    end
  end

  defp extract_identifier([char | rest], line, _acc),
    do: unexpected_character(char, line, rest)

  defp extract_identifier([], line, _acc),
    do: {{:error, "Unexpected end of input. Are you missing a closing bracket?"}, line, []}

  defp get_identifier_token(id) when id in @reserved_identifiers do
    {:builtin, format_identifier(id, true)}
  end

  defp get_identifier_token(id) when id in @custom_syntax do
    {:custom_syntax, format_identifier(id, true)}
  end

  defp get_identifier_token(id) do
    {:identifier, format_identifier(id, false)}
  end

  defp format_identifier(identifier, as_atom?) do
    formatted = String.replace(identifier, "-", "_")
    if as_atom?, do: String.to_atom(formatted), else: formatted
  end

  defp build_error(line, reason),
    do: {:error, "syntax error on `line #{line}`: #{reason}"}

  defp unexpected_character(char, line, rest),
    do: {{:error, ~s(unexpected character "#{char}".)}, line, rest}
end
