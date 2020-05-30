defmodule Language.Interpreter.Macros do
  @moduledoc """
  Helper macros for the interpreter.
  """

  import Language.Formatter, only: [format_identifier: 1]

  defmacro expr(name, opts \\ [], fun) do
    min_length = Keyword.get(opts, :min_length)
    max_length = Keyword.get(opts, :max_length)
    allowed_types = Keyword.get(opts, :allowed)

    quote do
      def reduce_expr({unquote(name), args}, state) do
        with {:ok, args} <-
               reduce_args(args, state),
             {:ok, args} <-
               verify_length(unquote(name), args, :min_length, unquote(min_length)),
             {:ok, args} <-
               verify_length(unquote(name), args, :max_length, unquote(max_length)),
             {:ok, args} <-
               verify_types(unquote(name), unquote(allowed_types), args, state) do
          unquote(fun).(args, state)
        end
      end
    end
  end

  def verify_types(caller, :string, args, _state) do
    not_a_string = Enum.find(args, &(not is_bitstring(&1)))

    if not_a_string do
      {:error, type_error("a string", caller, not_a_string)}
    else
      :ok
    end
  end

  def verify_types(caller, :integer, args, _state) do
    not_an_integer = Enum.find(args, &(not is_integer(&1)))

    if not_an_integer do
      {:error, type_error("an integer", caller, not_an_integer)}
    else
      :ok
    end
  end

  def verify_types(caller, :boolean, args, _state) do
    not_a_boolean = Enum.find(args, &(not is_boolean(&1)))

    if not_a_boolean do
      {:error, type_error("a boolean", caller, not_a_boolean)}
    else
      :ok
    end
  end

  def verify_types(caller, :tile, args, _state) do
    not_a_tile = Enum.find(args, &(not match?({x, y} when is_integer(x) and is_integer(y), &1)))

    if not_a_tile do
      {:error, type_error("a tile", caller, not_a_tile)}
    else
      :ok
    end
  end

  def verify_types(caller, :role, args, %{roles: roles}) do
    not_a_role = Enum.find(args, &(&1 not in roles))

    if not_a_role do
      {:error, type_error("a valid role", caller, not_a_role)}
    else
      :ok
    end
  end

  def verify_types(_caller, :role, _args, _state) do
    raise ArgumentError,
          "the game state must contain a :roles key for functions with a type of :role to be verified"
  end

  def verify_types(caller, types, args, state) when is_list(types) do
    bad_value =
      Enum.reduce_while(args, nil, fn value, acc ->
        type_matches =
          types
          |> Enum.map(&verify_types(caller, &1, [value], state))
          |> Enum.filter(&(&1 === :ok))

        case type_matches do
          [] ->
            {:halt, value}

          [_ | _] ->
            {:cont, acc}
        end
      end)

    if bad_value do
      {:error,
       "the `#{format_identifier(caller)}` function accepts types of #{Enum.join(types)}, but #{
         format_identifier(inspect(bad_value))
       } was passed instead"}
    else
      :ok
    end
  end

  def verify_types(_caller, _types, args, _state) do
    {:ok, args}
  end

  defp type_error(type, caller, value) do
    "#{type} was expected in the call to `#{format_identifier(caller)}`, but `#{
      format_identifier(inspect(value))
    }` was found instead"
  end

  def verify_length(func, args, :min_length, min_length) when is_integer(min_length) do
    if length(args) >= min_length do
      {:ok, args}
    else
      {:error, "the `#{func}` function requires a minimum of #{min_length} arguments"}
    end
  end

  def verify_length(func, args, :max_length, max_length) when is_integer(max_length) do
    if length(args) <= max_length do
      {:ok, args}
    else
      {:error, "the `#{func}` function accepts a maximum of #{max_length} arguments"}
    end
  end

  def verify_length(_, args, _, _), do: {:ok, args}
end
