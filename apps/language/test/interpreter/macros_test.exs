defmodule Language.Interpreter.MacrosTest do
  use ExUnit.Case, async: true

  import Language.Interpreter.Macros

  describe "verify_types/4" do
    test "correctly identifies valid strings" do
      args = ["everything", "here", "is", "a", "string"]
      assert :ok = verify_types(:+, :string, args, %{})
    end

    test "correctly identifies invalid strings" do
      args = ["string", "another", 10, "more string"]
      assert {:error, message} = verify_types(:+, :string, args, %{})
      assert message =~ "10"
    end

    test "correctly identifies valid integers" do
      args = [1, 2, 3, 4, 5]
      assert :ok = verify_types(:+, :integer, args, %{})
    end

    test "correctly identifies invalid integers" do
      args = ["string", "another", 10, "more string"]
      assert {:error, message} = verify_types(:+, :integer, args, %{})
      assert message =~ "string"
    end

    test "correctly identifies valid booleans" do
      args = [true, true, false, true]
      assert :ok = verify_types(:+, :boolean, args, %{})
    end

    test "correctly identifies invalid booleans" do
      args = [true, false, true, true, 11, false]
      assert {:error, message} = verify_types(:+, :boolean, args, %{})
      assert message =~ "11"
    end

    test "correctly identifies valid tiles" do
      args = [{1, 1}, {0, 21}, {18, 11}]
      assert :ok = verify_types(:+, :tile, args, %{})
    end

    test "correctly identifies invalid tiles" do
      args = ["not a tile", {4, 5}, {8, 9}]
      assert {:error, message} = verify_types(:+, :tile, args, %{})
      assert message =~ "not a tile"
    end

    test "correctly identifies valid roles" do
      state = %{roles: [:john, :tony, :cheryl, :bob]}
      args = [:john, :tony, :cheryl]
      assert :ok = verify_types(:+, :role, args, state)
    end

    test "correctly identifies invalid roles" do
      state = %{roles: [:john, :tony, :cheryl, :bob]}
      args = [:john, :tony, :cheryl, :william]
      assert {:error, message} = verify_types(:+, :role, args, state)
      assert message =~ "william"
    end

    test "raises if roles are tested for but a role map isn't passed" do
      assert_raise ArgumentError, fn ->
        args = [:john, :tony, :cheryl, :william]
        verify_types(:+, :role, args, %{})
      end
    end

    test "correctly identifies multiple valid types" do
      types = [:string, :boolean, :tile]
      args = ["tony", "john", {1, 1}, false, true, "hello", {2, 1}]
      assert :ok = verify_types(:+, types, args, %{})
    end

    test "correctly identifies multiple invalid types" do
      types = [:string, :boolean, :tile]
      args = ["tony", "john", {1, 1}, false, 11, true, "hello", {2, 1}]
      assert {:error, message} = verify_types(:+, types, args, %{})
      assert message =~ "11"
    end
  end
end
