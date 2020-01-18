defmodule ServerWeb.GameDebugView do
  use ServerWeb, :view

  def format_start_time(dt) do
    "#{dt.day}/#{dt.month}/#{dt.year} #{dt.hour}:#{dt.minute}:#{dt.second}"
  end

  def format_role_positions(positions) do
    str =
      Enum.reduce(positions, "", fn {role, position}, acc ->
        acc <> "#{role}: #{inspect(position)},"
      end)

    # Remove last comma
    String.slice(str, 0..-2)
  end
end
