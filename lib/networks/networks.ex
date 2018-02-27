defmodule UniCLI.Networks do
  @list_headers ~w(
    ID
    Name
    Enabled
    Purpose
    Subnet
    Domain
    VLAN
  )

  def run(settings, subcommands, options) do
    case subcommands do
      [:wlan | subcommands] ->
        UniCLI.Networks.Wireless.run(settings, subcommands, options)

      [:list] ->
        list(settings, options)
    end
  end

  def list(settings, _) do
    case UniCLI.HTTP.request(settings, :get, "/rest/networkconf") do
      {:ok, %{"data" => networks}} ->
        networks
        |> Enum.map(fn network ->
          {[
             network["_id"],
             network["name"],
             if(
               network["enabled"],
               do: "✓",
               else: "✗"
             ),
             network["purpose"],
             network["ip_subnet"],
             network["domain_name"],
             network["vlan"]
           ], []}
        end)
        |> Enum.unzip()
        |> UniCLI.Util.tableize(@list_headers, "No networks found.")

      {:error, error} ->
        IO.puts("ERROR: could not get data: #{error}")
    end
  end
end
