defmodule Editor.TestHelpers do
  alias Editor.{Accounts, Games}

  def user_fixture(attrs \\ %{}) do
    name = "user#{System.unique_integer([:positive])}"

    {:ok, %{user: user}} =
      attrs
      |> Enum.into(%{name: name, password: "12345678", email: "#{name}@test.com"})
      |> Accounts.create_account()

    user
  end

  def game_fixture(user_id, _attrs \\ %{}) do

    {:ok, game} = Games.create_game(user_id)

    game
  end
end
