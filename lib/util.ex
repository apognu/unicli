defmodule UniCLI.Util do
  def tableize(rows, headers) do
    rows
    |> TableRex.Table.new(headers)
    |> TableRex.Table.put_column_meta(0, padding: 0)
    |> TableRex.Table.put_column_meta(1..1000, padding: 1)
    |> TableRex.Table.render!(horizontal_style: :off, vertical_style: :off)
    |> IO.puts()
  end
end
