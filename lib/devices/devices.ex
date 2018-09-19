defmodule UniCLI.Devices do
  @list_headers [
    "ID",
    "Model",
    "Name",
    "State",
    "IP address",
    "MAC address",
    "Uptime",
    "Version",
    "RX bytes",
    "TX bytes"
  ]

  @states %{
    # Restarting?
    "0" => "Disconnected",
    "1" => "Connected",
    "2" => "Pending adoption",
    "3" => "Pending upgrade",
    "4" => "Upgrading",
    "5" => "Provisionning",
    "6" => "Heartbeat missed",
    "7" => "Adopting",
    "8" => "Deleting",
    "9" => "Inform error",
    "10" => "Adoption required",
    "11" => "Adoption failed",
    "12" => "Isolated",
    "13" => "RF scanning",
    "14" => "Managed by other",
    "15" => "Unknown"
  }

  def run(settings, subcommands, options) do
    case subcommands do
      [:list] ->
        list(settings, options)

      [:ports | subcommands] ->
        case subcommands do
          [:list] -> UniCLI.Devices.Ports.list(settings, options)
          [:enable] -> UniCLI.Devices.Ports.set_state(settings, true, options)
          [:disable] -> UniCLI.Devices.Ports.set_state(settings, false, options)
        end

      [:locate] ->
        locate(settings, options)

      [:provision] ->
        UniCLI.Devices.Manage.provision(settings, options)

      [:restart] ->
        UniCLI.Devices.Manage.restart(settings, options)

      [:adopt] ->
        UniCLI.Devices.Manage.adopt(settings, options)

      [] ->
        IO.puts("ERROR: unknown command")
    end
  end

  def list(settings, _) do
    case UniCLI.HTTP.request(settings, :get, "/stat/device") do
      {:ok, %{"data" => devices}} ->
        devices
        |> Enum.with_index()
        |> Enum.map(fn {device, row} ->
          ip =
            if Map.has_key?(device, "network_table") do
              # Router
              network =
                Enum.filter(device["network_table"], fn network ->
                  network["attr_no_delete"] == true
                end)

              if length(network) == 0, do: %{"ip" => ""}, else: hd(network)
            else
              # Other devices
              device
            end

          uptime =
            case device["uptime"] do
              int when is_integer(int) ->
                int
                |> Timex.Duration.from_seconds()
                |> Timex.format_duration(UniCLI.DurationFormatter)

              string when is_binary(string) ->
                case Integer.parse(string) do
                  {uptime, _} ->
                    uptime
                    |> Timex.Duration.from_seconds()
                    |> Timex.format_duration(UniCLI.DurationFormatter)

                  :error ->
                    "-"
                end

              _ ->
                "-"
            end

          colors = []

          colors =
            case @states[to_string(device["state"])] do
              "Disconnected" -> [{3, row, UniCLI.Util.danger()} | colors]
              "Connected" -> [{3, row, UniCLI.Util.ok()} | colors]
              _ -> [{3, row, UniCLI.Util.warning()} | colors]
            end

          colors =
            if device["upgradable"], do: [{7, row, UniCLI.Util.warning()} | colors], else: colors

          {[
             device["_id"],
             device["model"],
             device["name"],
             @states[to_string(device["state"])] || "Unknown",
             if(ip["ip"] != "", do: ip["ip"], else: "-"),
             device["mac"],
             uptime,
             "#{
               if(
                 device["upgradable"],
                 do: "⬆ ",
                 else: "✓ "
               )
             }#{device["version"]}",
             Size.humanize!(device["rx_bytes"] || 0),
             Size.humanize!(device["tx_bytes"] || 0)
           ], colors}
        end)
        |> Enum.unzip()
        |> UniCLI.Util.tableize(@list_headers, "No devices found.")

      {:error, error} ->
        IO.puts("ERROR: could not get data: #{error}")
    end
  end

  def locate(settings, %Optimus.ParseResult{args: %{id: id, state: state}}) do
    cmd = if state, do: "set-locate", else: "unset-locate"

    case UniCLI.Misc.Devices.get_device(settings, id) do
      {:ok, device} ->
        payload = %{
          "cmd" => cmd,
          "mac" => device["mac"]
        }

        case UniCLI.HTTP.request(settings, :post, "/cmd/devmgr", payload) do
          {:ok, _} ->
            IO.puts("Location state for '#{id}' was changed.")

          {:error, error} ->
            IO.puts("ERROR: could not set location state: #{error}")
        end

      {:error, error} ->
        IO.puts("ERROR: #{error}")
    end
  end
end
