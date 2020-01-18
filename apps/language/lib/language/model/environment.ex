defmodule Language.Environment do
  @moduledoc """

  """

  alias __MODULE__

  defstruct [:values]

  @type t :: %__MODULE__{values: %{required(String.t()) => term}}

  @doc """
  Creates a new empty environment.
  """
  @spec new() :: t
  def new() do
    %Environment{values: %{}}
  end

  @doc """
  Fetches the value associated with `name` in the environment and
  raises if the value doesn't exist.

  ## Examples

      iex> Language.Environment.new()
      ... |> Language.Environment.set!("name", "john")
      ... |> Language.Environment.get!("name")
      "john"

  """
  @spec get(t, String.t()) :: {:ok, any} | :not_found
  def get(%Environment{values: values}, name) do
    if value = values[name] do
      {:ok, value}
    else
      :not_found
    end
  end

  @doc """
  Associates `name` with `value` in the environment.

  Names must be unique and cannot be overwritten, so this
  function will raise if the value already exists.

  ## Examples

      iex> Language.Environment.new()
      ... |> Language.Environment.set!("name", "john")
      ... |> Language.Environment.get!("name")
      "john"

  """
  @spec set(t, String.t(), term) :: {:ok, t} | :exists
  def set(%Environment{values: values} = env, name, value) do
    if not Map.has_key?(values, name) do
      {:ok, %{env | values: Map.put(values, name, value)}}
    else
      :exists
    end
  end

  @doc """
  Replaces the given value in the

  ## Examples

      iex> Language.Environment.new()
      ... |> Language.Environment.set!("name", "john")
      ... |> Language.Environment.replace!("name", "steve")
      ... |> Language.Environment.get!("name")
      "steve"

  """
  @spec replace(t, String.t(), term) :: {:ok, t} | :not_found
  def replace(%Environment{values: values} = env, name, value) do
    if Map.has_key?(values, name) do
      {:ok, %{env | values: Map.put(values, name, value)}}
    else
      :not_found
    end
  end
end
