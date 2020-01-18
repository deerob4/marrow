defmodule EditorWeb.CheckAuth do
  @moduledoc """
  Plug module that prevents a route from being accessed unless
  a valid authentication token is contained within the request
  header.
  """

  import Plug.Conn
  alias Editor.{Auth, Repo}
  alias Editor.Auth.AuthToken

  def init(opts), do: opts

  def call(conn, _opts) do
    with {:ok, token} <- extract_auth_token(conn),
         {:ok, %AuthToken{} = token} <- Auth.get_token(token) do
      user = Repo.preload(token, :user).user

      conn
      |> assign(:token, token.token)
      |> authorised(user)
    else
      _ -> unauthorised(conn)
    end
  end

  defp extract_auth_token(conn) do
    case Plug.Conn.get_req_header(conn, "authorization") do
      [auth_header] -> get_token_from_header(auth_header)
      _ -> {:error, :missing_auth_header}
    end
  end

  defp get_token_from_header(auth_header) do
    {:ok, reg} = Regex.compile("Bearer\:?\s+(.*)$", "i")

    case Regex.run(reg, auth_header) do
      [_, match] -> {:ok, String.trim(match)}
      _ -> {:error, "token not found"}
    end
  end

  defp authorised(conn, user) do
    conn
    |> assign(:user, user)
  end

  defp unauthorised(conn) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(:forbidden, "unauthorised")
    |> halt()
  end
end
