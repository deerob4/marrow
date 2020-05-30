defmodule Language.Protocol.Functions do
  @moduledoc """
  Functions are expressions that will always return a value, given an
  appropriate input.
  """

  use Language.Protocol

  alias Language.Protocol

  @doc marrow: %{
         name: "+",
         body: "Returns the sum of all the arguments.",
         category: :logic,
         kind: :function,
         examples: [
           %{input: "(+ 1 2 3 (+ 4 5) 6)", output: "21"}
         ]
       }
  @callback plus([integer()]) :: integer()

  @doc marrow: %{
         name: "-",
         body: "Returns the result of subtracting each argument from the next argument.",
         category: :logic,
         kind: :function,
         examples: [
           %{input: "(- 3 2)", output: "1"}
         ]
       }
  @callback minus([integer()]) :: integer()

  @doc marrow: %{
         name: "*",
         body: "Returns the product of all the arguments.",
         category: :logic,
         kind: :function,
         examples: [
           %{input: "(* 3 (* 10 10) 2)", output: "600"}
         ]
       }
  @callback multiply([integer()]) :: integer()

  @doc marrow: %{
         name: "/",
         body: "Performs integer division on all the numbers in the list.",
         category: :logic,
         kind: :function,
         examples: [
           %{input: "(/ 90 30)", output: "3"}
         ]
       }
  @callback divide([integer()]) :: integer()

  @doc marrow: %{
         name: "/",
         body: "Returns the modulus of all the numbers in the list.",
         category: :logic,
         kind: :function,
         examples: [
           %{input: "(% 10 2)", output: "0"}
         ]
       }
  @callback mod([integer()]) :: integer()

  @doc marrow: %{
         name: "<",
         body: "Returns `true` if every argument is smaller than the one after it.",
         category: :logic,
         kind: :function,
         examples: [
           %{input: "(< 10 20 30)", output: "true"},
           %{input: "(< 10 20 40 30)", output: "false"}
         ]
       }
  @callback lt?([integer()]) :: boolean()

  @doc marrow: %{
         name: "<=",
         body: "Returns `true` if every argument is smaller than or equal to the one after it.",
         category: :logic,
         kind: :function,
         examples: [
           %{input: "(<= 10 20 30)", output: "true"},
           %{input: "(<= 10 20 40 30)", output: "false"}
         ]
       }
  @callback lte?([integer()]) :: boolean()

  @doc marrow: %{
         name: ">",
         body: "Returns `true` if every argument is larger than the one after it.",
         category: :logic,
         kind: :function,
         examples: [
           %{input: "(> 30 20 10)", output: "true"},
           %{input: "(> 40 30 10 20)", output: "false"}
         ]
       }
  @callback gt?([integer()]) :: boolean()

  @doc marrow: %{
         name: ">=",
         body: "Returns `true` if every argument is larger than or equal to the one after it.",
         category: :logic,
         kind: :function,
         examples: [
           %{input: "(>= 30 20 10)", output: "true"},
           %{input: "(>= 40 30 10 20)", output: "false"}
         ]
       }
  @callback gte?([integer()]) :: boolean()

  @doc marrow: %{
         name: "=",
         body: "Returns `true` if all the items in the list are equal, otherwise `false`.",
         category: :logic,
         kind: :function,
         examples: [
           %{input: "(= true true)", output: "true"},
           %{input: "(= true (= true false))", output: "false"}
         ]
       }
  @callback eq?([boolean()]) :: boolean()

  @doc marrow: %{
         name: "!=",
         body: "Returns `true` if none of the items in the list are equal, otherwise `false`.",
         category: :logic,
         kind: :function,
         examples: [
           %{input: "(= true true)", output: "false"},
           %{input: "(= true (= true false))", output: "true"}
         ]
       }
  @callback neq?([boolean()]) :: boolean()

  @doc marrow: %{
         name: "and",
         body:
           "Logical `AND` conjunction. Returns `true` if all expressions evaluate themselves to `true`, otherwise `false`.",
         category: :logic,
         kind: :function,
         examples: [
           %{
             input: "(and (= 10 10) (!= 20 10))",
             output: "true"
           }
         ]
       }
  @callback and?([boolean()]) :: boolean()

  @doc marrow: %{
         name: "or",
         body:
           "Logical `OR` conjunction. Returns `true` if at least one expression evaluates to `true`, otherwise `false`.",
         category: :logic,
         kind: :function,
         examples: [
           %{
             input: "(or (= 10 10) (!= 20 20))",
             output: "true"
           }
         ]
       }
  @callback or?([boolean()]) :: boolean()

  @doc marrow: %{
         name: "not",
         body: "Logical `NOT` operation. Returns the logical negation of the given Boolean.",
         category: :logic,
         kind: :function,
         examples: [
           %{input: "(not true)", output: "false"},
           %{input: "(not (not (not false)))", output: "true"}
         ]
       }
  @callback not?(boolean()) :: boolean()

  @doc marrow: %{
         name: "min",
         body: "Returns the smallest number in the list.",
         category: :logic,
         kind: :function,
         examples: [
           %{input: ~S{(min (100 38 903 90 22))}, output: "22"}
         ]
       }
  @callback min([integer()]) :: integer()

  @doc marrow: %{
         name: "max",
         body: "Returns the largest number in the list.",
         category: :logic,
         kind: :function,
         examples: [
           %{input: ~S{(max (100 38 903 90 22))}, output: "903"}
         ]
       }
  @callback max([integer()]) :: integer()

  @doc marrow: %{
         name: "player-tile",
         body: "Returns the board tile that the given role is currently on.",
         category: :players,
         kind: :logic,
         examples: [
           %{input: "(player-tile john)", output: "(1 1)"},
           %{input: "(player-tile ?current-player)", output: "(2 2)"}
         ]
       }
  @callback player_tile(Protocol.role(), map) :: Protocol.tile()

  @doc marrow: %{
         name: "rand-int",
         body: "Returns a random number between the two arguments, inclusive.",
         category: :logic,
         kind: :function,
         examples: [
           %{input: ~S{(rand-int 1 100)}, output: "16"}
         ]
       }
  @callback rand_int(integer(), integer()) :: integer()

  @doc marrow: %{
         name: "concat",
         body: "Concatenates all of the strings into one single string.",
         category: :logic,
         kind: :function,
         examples: [
           %{
             input: ~S{(concat "Hello" " " "world")},
             output: "Hello world"
           },
           %{
             input: ~S{(concat "Hello" (concat " there " " friend") "!")},
             output: "Hello there friend!"
           }
         ]
       }
  @callback concat([String.t()]) :: String.t()

  @doc marrow: %{
         name: "choose-random",
         body: "Returns a random item from the given list.",
         category: :logic,
         kind: :function,
         examples: [
           %{
             input: ~S{(choose-random (john "smith" "argentina" 10))},
             output: "john"
           }
         ]
       }
  @callback choose_random([Protocol.type()]) :: Protocol.type()

  # @doc marrow: %{
  #        name: "var",
  #        body: "Returns the value of the given variable",
  #        category: :variables,
  #        kind: :logic,
  #        examples: [
  #          %{input: "(var score)", output: "1"},
  #          %{input: "(+ (var score) 2)", output: "3"}
  #        ]
  #      }

  # @callback var(identifier()) :: Protocol.type()

  defmacro __using__(_) do
    quote do
      @behaviour Language.Protocol.Functions
    end
  end
end
