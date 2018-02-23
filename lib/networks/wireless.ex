defmodule UniCLI.Networks.Wireless do
  @list_headers ~w(
    ID
    Name
    Enabled
    Security
    Encryption
    VLAN
  )

  def run(settings, subcommands, options) do
    case subcommands do
      [:list | _] -> list(settings, options)
      [:enable | _] -> set_state(settings, true, options)
      [:disable | _] -> set_state(settings, false, options)
    end
  end

  def list(settings, _) do
    case UniCLI.HTTP.request(settings, :get, "/rest/wlanconf") do
      {:ok, %{"data" => networks}} ->
        networks
        |> Enum.map(fn network ->
          [
            network["_id"],
            network["name"],
            if(network["enabled"], do: "✓", else: "✗"),
            network["security"],
            "#{network["wpa_mode"]}/#{network["wpa_enc"]}",
            network["vlan"]
          ]
        end)
        |> UniCLI.Util.tableize(@list_headers, "No wireless networks found.")

      {:error, error} ->
        IO.puts("ERROR: could not get data: #{error}")
    end
  end

  def set_state(settings, state, %Optimus.ParseResult{args: %{id: id}}) do
    case UniCLI.HTTP.request(settings, :put, "/rest/wlanconf/" <> id, %{"enabled" => state}) do
      {:ok, _} ->
        if state do
          IO.puts("Wireless network '#{id}' was enabled.")
        else
          IO.puts("Wireless network '#{id}' was disabled.")
        end

      {:error, error} ->
        if state do
          IO.puts("ERROR: could not enable wireless network: #{error}")
        else
          IO.puts("ERROR: could not disable wireless network: #{error}")
        end
    end
  end
end
