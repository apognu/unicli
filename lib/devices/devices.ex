defmodule UniCLI.Devices do
  @list_headers [
    "ID",
    "Model",
    "Name",
    "IP address",
    "MAC address",
    "Uptime",
    "Version",
    "RX bytes",
    "TX bytes"
  ]

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
    end
  end

  def list(settings, _) do
    case UniCLI.HTTP.request(settings, :get, "/stat/device") do
      {:ok, %{"data" => devices}} ->
        devices
        |> Enum.map(fn device ->
          ip =
            if Map.has_key?(device, "network_table") do
              network =
                Enum.filter(device["network_table"], fn network ->
                  network["attr_no_delete"] == true
                end)

              if length(network) == 0, do: %{"ip" => ""}, else: hd(network)
            else
              device
            end

          uptime =
            Timex.Duration.from_seconds(device["uptime"])
            |> Timex.format_duration(UniCLI.DurationFormatter)

          [
            device["_id"],
            device["model"],
            device["name"],
            ip["ip"],
            device["mac"],
            uptime,
            "#{
              if(
                device["upgrade_to_firmware"] != device["version"],
                do: "✓ ",
                else: "⬆ "
              )
            }#{device["version"]}",
            Size.humanize!(device["rx_bytes"]),
            Size.humanize!(device["tx_bytes"])
          ]
        end)
        |> UniCLI.Util.tableize(@list_headers)

      {:error, error} ->
        IO.puts("ERROR: could not get data (#{error})")
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
            IO.puts("ERROR: could not set state: #{error}")
        end

      {:error, error} ->
        IO.puts("ERROR: #{error}")
    end
  end
end
