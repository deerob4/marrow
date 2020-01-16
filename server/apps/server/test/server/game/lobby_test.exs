defmodule Server.Game.LobbyTest do
  use ExUnit.Case, async: true

  alias Server.Game.Lobby

  @roles ["a", "b", "c"]
  @password "12345678"

  describe "requires_password?/1" do
    test "returns true when the game is setup with a password" do
      lobby = start_supervised!({Lobby, {@roles, @password}})
      assert Lobby.requires_password?(lobby)
    end

    test "returns false when the game is setup without a password" do
      lobby = start_supervised!({Lobby, {@roles, nil}})
      refute Lobby.requires_password?(lobby)
    end
  end

  describe "valid_password?/2" do
    test "returns true when the password is valid" do
      lobby = start_supervised!({Lobby, {@roles, @password}})
      assert Lobby.valid_password?(lobby, @password)
    end

    test "returns false when the password is invalid" do
      lobby = start_supervised!({Lobby, {@roles, @password}})
      refute Lobby.valid_password?(lobby, "jkdsfal")
    end

    test "returns true when a password has not been set." do
      lobby = start_supervised!({Lobby, {@roles, nil}})
      assert Lobby.valid_password?(lobby, "123")
    end
  end

  test "list_roles/1" do
    lobby = start_supervised!({Lobby, {@roles, @password}})

    assert Lobby.list_roles(lobby) === [
             %{name: "a", available?: true},
             %{name: "b", available?: true},
             %{name: "c", available?: true}
           ]
  end

  test "select_role/2" do
    lobby = start_supervised!({Lobby, {@roles, @password}})

    assert :ok = Lobby.select_role(lobby, "a")

    assert Lobby.list_roles(lobby) === [
             %{name: "a", available?: false},
             %{name: "b", available?: true},
             %{name: "c", available?: true}
           ]

    assert {:error, :already_taken} = Lobby.select_role(lobby, "a")
  end

  test "release_role/2" do
    lobby = start_supervised!({Lobby, {@roles, @password}})
    assert :ok = Lobby.select_role(lobby, "a")
    assert :ok = Lobby.release_role(lobby, "a")

    assert Lobby.list_roles(lobby) === [
      %{name: "a", available?: true},
      %{name: "b", available?: true},
      %{name: "c", available?: true}
    ]
  end
end
