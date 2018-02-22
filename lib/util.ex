defmodule UniCLI.Util do
  @sites_headers [
    "ID",
    "Name"
  ]

  def env(var) do
    case System.get_env(var) do
      nil -> :error
      value -> {:ok, value}
    end
  end

  def sites(settings, _, _) do
    case UniCLI.HTTP.sites(settings) do
      {:ok, %{"data" => sites}} ->
        Enum.map(sites, fn site ->
          [
            site["name"],
            site["desc"]
          ]
        end)
        |> UniCLI.Util.tableize(@sites_headers)

      {:error, error} ->
        IO.puts("ERROR: could not get data: #{error}")
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
