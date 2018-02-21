defmodule UniCLI.Clients do
  @list_headers [
    "MAC address",
    "Make",
    "Hostname",
    "Network",
    "IP address",
    "Last seen",
    "Wired?",
    "Guest?",
    "WAN up",
    "WAN down",
    "LAN up",
    "LAN down"
  ]

  def run(settings, subcommands, options) do
    case subcommands do
      [:list] -> list(settings, options)
      [:block] -> set_state(settings, true, options)
      [:unblock] -> set_state(settings, false, options)
    end
  end

  def list(settings, _) do
    case UniCLI.HTTP.request(settings, :get, "/stat/sta") do
      {:ok, %{"data" => clients}} ->
        clients
        |> Enum.map(fn client ->
          seen =
            case client["last_seen"] do
              nil ->
                "Never"

              since ->
                Timex.from_unix(since, :second)
                |> Timex.format!("{relative}", :relative)
            end

          [
            client["mac"],
            client["oui"],
            client["hostname"],
            client["network"],
            client["ip"],
            seen,
            if(client["is_wired"], do: "✓", else: "✗"),
            if(client["is_guest"], do: "✓", else: "✗"),
            Size.humanize!(client["rx_bytes"] || 0),
            Size.humanize!(client["tx_bytes"] || 0),
            Size.humanize!(client["wired-rx_bytes"] || 0),
            Size.humanize!(client["wired-tx_bytes"] || 0)
          ]
        end)
        |> UniCLI.Util.tableize(@list_headers)

      {:error, error} ->
        IO.puts("ERROR: could not get data: #{error}")
    end
  end

  def set_state(settings, state, %Optimus.ParseResult{args: %{mac: client_mac}}) do
    cmd = if state, do: "block-sta", else: "unblock-sta"

    case UniCLI.HTTP.request(settings, :post, "/cmd/stamgr", %{
           "cmd" => cmd,
           "mac" => client_mac
         }) do
      {:ok, _} ->
        IO.puts("Block state for '#{client_mac}' was changed.")

      {:error, error} ->
        IO.puts("ERROR: could not set state: #{error}")
    end
  end
end
