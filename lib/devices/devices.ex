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

  @ports_headers [
    "ID",
    "Name",
    "Enabled",
    "Link",
    "STP state",
    "Speed",
    "Duplex",
    "RX bytes",
    "TX bytes"
  ]

  def run(settings, subcommands, options) do
    case subcommands do
      [:list] ->
        list(settings, options)

      [:ports | subcommands] ->
        case subcommands do
          [:list] -> ports(settings, options)
          [:enable] -> set_state(settings, true, options)
          [:disable] -> set_state(settings, false, options)
        end
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

  def ports(settings, %Optimus.ParseResult{args: %{id: id}}) do
    case UniCLI.HTTP.request(settings, :get, "/stat/device") do
      {:ok, %{"data" => devices}} ->
        devices =
          devices
          |> Enum.filter(fn device -> device["_id"] == id end)

        case length(devices) do
          0 ->
            IO.puts("ERROR: device not found")

          _ ->
            device = hd(devices)

            device["port_table"]
            |> Enum.map(fn port ->
              [
                port["port_idx"] || "-",
                port["name"],
                if(port["enable"], do: "✓", else: "✗"),
                if(port["up"], do: "UP", else: "DOWN"),
                port["stp_state"] || "-",
                port["speed"],
                if(port["full_duplex"], do: "FDX", else: "HDX"),
                Size.humanize!(port["rx_bytes"]),
                Size.humanize!(port["tx_bytes"])
              ]
            end)
            |> UniCLI.Util.tableize(@ports_headers)
        end

      {:error, error} ->
        IO.puts("ERROR: could not get data (#{error})")
    end
  end

  def set_state(settings, state, %Optimus.ParseResult{args: %{device_id: device_id, id: id}}) do
    with {:ok, port_confs} <- UniCLI.Misc.Ports.list_configurations(settings),
         {:ok, device} <- UniCLI.Misc.Devices.get_device(settings, device_id),
         {:ok, port_overrides} = UniCLI.Misc.Ports.list_port_overrides(settings, device["mac"]) do
      ports =
        String.split(id, ",")
        |> Enum.map(fn range -> String.split(range, "-") end)
        |> Enum.map(fn
          port when length(port) == 1 ->
            hd(port)

          [left, right] = port when length(port) == 2 ->
            with {left, _} <- Integer.parse(left),
                 {right, _} <- Integer.parse(right) do
              left..right
              |> Enum.map(fn port -> to_string(port) end)
              |> Enum.to_list()
            else
              :error -> []
            end

          _ ->
            []
        end)
        |> List.flatten()
        |> Enum.map(fn port ->
          case Integer.parse(port) do
            {port, _} -> port
            :error -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)

      if Enum.any?(ports, fn port -> port > length(device["port_table"]) end) do
        IO.puts("ERROR: invalid port ID")
      else
        port_overrides =
          port_overrides
          |> Enum.map(fn override -> {override["port_idx"], override["portconf_id"]} end)
          |> Enum.into(%{})

        state_name = if(state, do: "All", else: "Disabled")

        state_id =
          port_confs
          |> Enum.filter(fn conf -> conf[:name] == state_name end)
          |> hd()
          |> Map.get(:id)

        port_overrides =
          ports
          |> Enum.reduce(port_overrides, fn port, acc ->
            Map.put(acc, port, state_id)
          end)
          |> Enum.map(fn {port, portconf_id} ->
            %{"port_idx" => port, "portconf_id" => portconf_id}
          end)

        case UniCLI.HTTP.request(settings, :put, "/rest/device/" <> device_id, %{
               "port_overrides" => port_overrides
             }) do
          {:ok, _} ->
            IO.puts("Port state #{device_id}/#{id} state changed.")

          {:error, error} ->
            IO.puts("ERROR: could not set port state (#{error})")
        end
      end
    else
      {:error, error} -> IO.puts("ERROR: could not get device configuration (#{error})")
    end
  end
end
