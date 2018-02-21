defmodule UniCLI.Events.Events do
  @list_headers [
    "Time",
    "System",
    "Message"
  ]

  def run(settings, _, _) do
    case UniCLI.HTTP.request(settings, :post, "/stat/event", %{"_limit" => 50}) do
      {:ok, %{"data" => events}} ->
        Enum.map(events, fn event ->
          [
            Timex.from_unix(event["time"], :millisecond)
            |> Timex.format!("%Y/%m/%d %l:%M%P", :strftime),
            String.upcase(event["subsystem"]) || "AUTH",
            event["msg"]
          ]
        end)
        |> UniCLI.Util.tableize(@list_headers)

      {:error, error} ->
        IO.puts("ERROR: could not get data: #{error}")
    end
  end
end
