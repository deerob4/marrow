defmodule Editor.Accounts do
  @moduledoc """
  Context module for accounts.

  The account system for the editor system is very simple. There
  is only one type of account, the `%Editor.Accounts.User{}`,
  each of whom is responsible for their own games.
  """

  alias Ecto.Multi
  alias Editor.{Auth, Games, Repo}
  alias Editor.Accounts.User

  @doc """
  Creates a new user account from the `account_params`.

  A default game will also be created and associated with this
  account, in order to given them something to start with.
  """
  def create_account(account_params) do
    Multi.new()
    |> Multi.insert(:user, User.registration_changeset(%User{}, account_params))
    |> Multi.run(:game, fn _, %{user: user} -> Games.create_game(user.id) end)
    |> Multi.run(:token, fn _, %{user: user} -> create_token(user) end)
    |> Repo.transaction()
  end

  @doc """
  Deletes the account for the user with the given `user_id`.

  This action will also delete all of their games and associated
  entitites.
  """
  def delete_account(user_id) do
    user = Repo.get!(User, user_id)
    Repo.delete(user)
  end

  @doc """
  Signs the user into the system if the given `email` and
  `password` match an existing account.

  If successful, this function creates a new authentication
  token, unique to the user, which can be used to authenticate
  additional requests.
  """
  def signin(email, password) do
    user = Repo.get_by(User, email: email)

    case Comeonin.Argon2.check_pass(user, password) do
      {:ok, user} ->
        {:ok, token} = create_token(user)
        {:ok, user, token}

      {:error, _} ->
        {:error, "unauthorised"}
    end
  end

  defp create_token(user) do
    token = Auth.generate_token(user.id)

    user
    |> Ecto.build_assoc(:auth_tokens, %{token: token})
    |> Repo.insert!()

    {:ok, token}
  end

  @doc """
  Returns the user associated with the give authentication
  `token` if they exist, otherwise `{:error, "unauthorised"}`.
  """
  def get_from_token(token) do
    with {:ok, _token} <- Auth.get_token(token),
         {:ok, user_id} <- Auth.verify_token(token) do
      {:ok, Repo.get!(User, user_id)}
    else
      _ ->
        {:error, "unauthorised"}
    end
  end

  @doc """
  Signs the user with the given `token` out.

  This will invalidate the token, preventing it from being used
  to authenticate additional requests.
  """
  def signout(token) do
    with {:ok, token} <- Auth.get_token(token) do
      Repo.delete(token)
    end
  end
end
