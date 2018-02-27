defmodule UniCLI.Util do
  @sites_headers [
    "ID",
    "Name",
    "Alerts",
    "WAN",
    "LAN",
    "WLAN",
    "VPN"
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
        sites
        |> Enum.with_index()
        |> Enum.map(fn {site, row} ->
          status =
            site["health"]
            |> Enum.map(fn health ->
              {health["subsystem"], health["status"] == "ok"}
            end)
            |> Map.new()

          colors =
            ~w(wan lan www vpn)
            |> Enum.with_index()
            |> Enum.map(fn {subsystem, column} ->
              if status[subsystem] do
                {3 + column, row, UniCLI.Util.ok()}
              else
                {3 + column, row, UniCLI.Util.warning()}
              end
            end)

          colors =
            if site["num_new_alarms"] > 0 do
              [{2, row, UniCLI.Util.warning()} | colors]
            else
              [{2, row, UniCLI.Util.ok()} | colors]
            end

          {[
             site["name"],
             site["desc"],
             site["num_new_alarms"],
             if(status["wan"], do: "✓", else: "✗"),
             if(status["lan"], do: "✓", else: "✗"),
             if(status["www"], do: "✓", else: "✗"),
             if(status["vpn"], do: "✓", else: "✗")
           ], colors}
        end)
        |> Enum.unzip()
        |> UniCLI.Util.tableize(@sites_headers)

      {:error, error} ->
        IO.puts("ERROR: could not get data: #{error}")
    end
  end

  def tableize({rows, colors}, headers, empty_message \\ "No data found") do
    if length(rows) == 0 do
      IO.puts(empty_message)
    else
      rows
      |> TableRex.Table.new(headers)
      |> colorize_table(colors)
      |> TableRex.Table.put_column_meta(0, padding: 0)
      |> TableRex.Table.put_column_meta(1..1000, padding: 1)
      |> TableRex.Table.render!(horizontal_style: :off, vertical_style: :off)
      |> IO.puts()
    end
  end

  def colorize_table(table, specs) do
    specs
    |> List.flatten()
    |> Enum.reduce(table, fn {x, y, color}, table ->
      TableRex.Table.put_cell_meta(table, x, y, color: IO.ANSI.color(color))
    end)
  end

  def danger(), do: 196
  def warning(), do: 130
  def ok(), do: 30
end
