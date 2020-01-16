defmodule Language.Model.Card do
  @moduledoc """
  Cards introduce a notion of interaction into the games.

  In many board games, it is common for events like
  "pick up a red card" on this tile to take place. These cards
  then allow the user to make a choice between certain actions.
  Cards in MarrowLang fulfill the same purpose, allowing the
  player to create choices that impact the game.
  """

  alias Language.{Compiler}

  import Language.Interpreter, only: [reduce_expr: 2]

  defstruct id: nil, title: nil, body: nil, stack: "default", actions: []

  defmodule Action do
    defstruct [:id, :title, :events]

    @type t :: %__MODULE__{id: String.t(), title: String.t(), events: Compiler.ast()}
  end

  @type action :: {String.t(), Compiler.ast()}

  @type t :: %__MODULE__{
          id: String.t(),
          title: String.t(),
          stack: String.t(),
          body: Compiler.ast(),
          actions: [Action.t()]
        }

  def evaluate(card, context) do
    with {:ok, body} <- reduce_expr(card.body, context),
         actions when is_list(actions) <- eval_actions(card.actions, context) do
      {:ok, %{title: card.title, body: body, actions: actions}}
    end
  end

  defp eval_actions(actions, context) do
    Enum.reduce_while(actions, [], fn %{title: title, id: id}, acc ->
      case reduce_expr(title, context) do
        {:ok, title} ->
          action = %{id: id, title: title}
          {:cont, [action | acc]}

        {:error, _} = error ->
          {:halt, error}
      end
    end)
  end
end

# cards =
#   {:cards,
#    [
#      {"card",
#       [
#         "Floods Down South",
#         {:stack, ["Bad Cards"]},
#         {:body,
#          [
#            if:
#              {{:>, [10, {"success_count", [:"?current_player"]}]},
#               {:concat,
#                [
#                  "Flooding has occured south of the border. ",
#                  {:if, {{"taken", ["a"]}, "a", ""}},
#                  {:if, {{"taken", ["b"]}, "b", ""}},
#                  {:if, {{"taken", ["c"]}, "c", ""}},
#                  " have been taken. Times are dire. What will you do?"
#                ]}, "Flooding has occured north of the border. What won't you do?"}
#          ]},
#         {:choices,
#          [
#            ["Move the troops", ["move_troops"]],
#            [
#              "Move the villagers",
#              {:decrement!, [{"success_count", [:"?current_player"]}]}
#            ],
#            ["Do fuck all", ["nothing"]]
#          ]}
#       ]}
#    ]}

# [
#   %Language.Card{
#     title: "Floods Down South",
#     stack: "Bad Cards",
#     body:
#       {:if,
#        {{:>, [10, {"success_count", [:"?current_player"]}]},
#         {:concat,
#          [
#            "Flooding has occured south of the border. ",
#            {:if, {{"taken", ["a"]}, "a", ""}},
#            {:if, {{"taken", ["b"]}, "b", ""}},
#            {:if, {{"taken", ["c"]}, "c", ""}},
#            " have been taken. Times are dire. What will you do?"
#          ]}, "Flooding has occured north of the border. What won't you do?"}},
#     actions: [
#       {"Move the villagers", {:decrement!, [{"success_count", [:"?current_player"]}]}},
#       {"Move the troops", {"move_troops", []}},
#       {"Do fuck all", {"nothing", []}}
#     ]
#   }
# ]

# 1. How do we inject the correct values in at run time?
