defmodule EditorWeb.AccountControllerTest do
  use EditorWeb.ConnCase

  @user %{name: "John Smith", email: "john@gmail.com", password: "12345678"}

  test "POST /api/accounts", %{conn: conn} do
    conn = post(conn, "/api/accounts", %{"account" => @user})
    assert response = json_response(conn, 200)
    assert response["message"] == "created"
  end
end
