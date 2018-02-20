defmodule UniCLI.Util do
  def env(var) do
    case System.get_env(var) do
      nil -> :error
      value -> {:ok, value}
    end
  end

  def tableize(rows, headers) do
    if length(rows) == 0 do
      IO.puts("Nothing to display.")
    else
      rows
      |> TableRex.Table.new(headers)
      |> TableRex.Table.put_column_meta(0, padding: 0)
      |> TableRex.Table.put_column_meta(1..1000, padding: 1)
      |> TableRex.Table.render!(horizontal_style: :off, vertical_style: :off)
      |> IO.puts()
    end
  end
end
