defmodule UniCLI.Events.Alerts do
  @list_headers [
    "",
    "Time",
    "System",
    "Device",
    "Message"
  ]

  def run(settings, _, _) do
    case UniCLI.HTTP.request(settings, :post, "/stat/alarm", %{"_limit" => 50}) do
      {:ok, %{"data" => alerts}} ->
        alerts
        |> Enum.with_index()
        |> Enum.map(fn {alert, row} ->
          device =
            cond do
              alert["gw_name"] -> alert["gw_name"]
              alert["ap_name"] -> alert["ap_name"]
              alert["sw_name"] -> alert["sw_name"]
              true -> "-"
            end

          colors =
            if alert["archived"],
              do: [{0, row, UniCLI.Util.ok()}],
              else: [{0, row, UniCLI.Util.warning()}]

          {[
             if(alert["archived"], do: "✓", else: "!"),
             Timex.from_unix(alert["time"], :millisecond)
             |> Timex.format!("%Y/%m/%d %l:%M%P", :strftime),
             String.upcase(alert["subsystem"]),
             device,
             alert["msg"]
           ], colors}
        end)
        |> Enum.unzip()
        |> UniCLI.Util.tableize(@list_headers, "No alerts found.")

      {:error, error} ->
        IO.puts("ERROR: could not get data: #{error}")
    end
  end
end
