defmodule Editor.Auth do
  alias Editor.Repo
  alias Editor.Auth.AuthToken

  @seed "rz(B\^h:E[e[>5yX~)93cr7TSanKX:p"

  @secret :crypto.strong_rand_bytes(30) |> Base.url_encode64() |> binary_part(0, 30)

  # 1 day
  @max_age 86400

  def generate_token(id) do
    Phoenix.Token.sign(@secret, @seed, id, max_age: @max_age)
  end

  def verify_token(token) do
    case Phoenix.Token.verify(@secret, @seed, token, max_age: @max_age) do
      {:ok, id} -> {:ok, id}
      error -> error
    end
  end

  @doc """
  Returns the `{:ok, Editor.Auth.AuthToken{}}` struct for the
  given `token` if it exists, otherwise `{:error, :not_found}`.
  """
  def get_token(token, opts \\ []) do
    revoked? = Keyword.get(opts, :revoked?, false)

    case Repo.get_by(AuthToken, token: token, revoked: revoked?) do
      nil -> {:error, :not_found}
      token -> {:ok, token}
    end
  end
end
