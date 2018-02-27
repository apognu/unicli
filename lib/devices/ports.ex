defmodule UniCLI.Devices.Ports do
  @list_headers [
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

  def list(settings, %Optimus.ParseResult{args: %{id: id}}) do
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
            |> Enum.with_index()
            |> Enum.map(fn {port, row} ->
              colors = []

              colors =
                case {port["enable"], port["up"]} do
                  {false, _} -> [{2, row, UniCLI.Util.warning()} | colors]
                  {true, true} -> [{2, row, UniCLI.Util.ok()}, {3, row, UniCLI.Util.ok()}]
                  {true, false} -> [{2, row, UniCLI.Util.ok()}, {3, row, UniCLI.Util.warning()}]
                end

              {[
                 port["port_idx"] || "-",
                 port["name"],
                 if(port["enable"], do: "✓", else: "✗"),
                 if(port["up"], do: "UP", else: "DOWN"),
                 port["stp_state"] || "-",
                 if(port["up"], do: port["speed"], else: "-"),
                 if(port["up"], do: if(port["full_duplex"], do: "FDX", else: "HDX"), else: "-"),
                 Size.humanize!(port["rx_bytes"] || 0),
                 Size.humanize!(port["tx_bytes"] || 0)
               ], colors}
            end)
            |> Enum.unzip()
            |> UniCLI.Util.tableize(@list_headers, "No ports found on this device.")
        end

      {:error, error} ->
        IO.puts("ERROR: could not get data: #{error}")
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

      if !port_overrides or Enum.any?(ports, fn port -> port > length(device["port_table"]) end) do
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
            IO.puts("Port state for '#{device_id} → #{id}' was changed.")

          {:error, error} ->
            IO.puts("ERROR: could not set port state: #{error}")
        end
      end
    else
      {:error, error} -> IO.puts("ERROR: could not get device configuration: #{error}")
    end
  end
end
