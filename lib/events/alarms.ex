defmodule UniCLI.Events.Alarms do
  @list_headers [
    "",
    "Time",
    "System",
    "Device",
    "Message"
  ]

  def run(settings, _, _) do
    case UniCLI.HTTP.request(settings, :post, "/stat/alarm", %{"_limit" => 50}) do
      {:ok, %{"data" => alarms}} ->
        Enum.map(alarms, fn alarm ->
          device =
            cond do
              alarm["ap_name"] -> alarm["ap_name"]
              alarm["gw_name"] -> alarm["gw_name"]
              true -> "-"
            end

          [
            if(alarm["archived"], do: "✓", else: "!"),
            Timex.from_unix(alarm["time"], :millisecond)
            |> Timex.format!("%Y/%m/%d %l:%M%P", :strftime),
            String.upcase(alarm["subsystem"]),
            device,
            alarm["msg"]
          ]
        end)
        |> UniCLI.Util.tableize(@list_headers)

      {:error, error} ->
        IO.puts("ERROR: could not get data: #{error}")
    end
  end
end
