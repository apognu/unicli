defmodule UniCLI.RADIUS do
  @headers [
    "ID",
    "Username",
    "VLAN"
  ]

  def run(settings, subcommands, options) do
    case subcommands do
      [:users | subcommands] ->
        case subcommands do
          [:list] -> list(settings, options)
          [:create] -> create(settings, options)
          [:delete] -> delete(settings, options)
        end
    end
  end

  def list(settings, _) do
    case UniCLI.HTTP.request(settings, :get, "/rest/account") do
      {:ok, %{"data" => users}} ->
        users
        |> Enum.map(fn user ->
          [
            user["_id"],
            user["name"],
            user["vlan"]
          ]
        end)
        |> UniCLI.Util.tableize(@headers, "No RADIUS users found.")

      {:error, error} ->
        IO.puts("ERROR: could not get data: #{error}")
    end
  end

  def create(settings, %Optimus.ParseResult{
        args: %{username: username, password: password},
        options: options
      }) do
    %{
      vlan: vlan,
      tunnel: tunnel,
      medium: medium
    } = options

    payload = %{
      "name" => username,
      "x_password" => password
    }

    payload = if vlan > 0, do: Map.put(payload, "vlan", vlan), else: payload
    payload = if tunnel > 0, do: Map.put(payload, "tunnel_type", tunnel), else: payload
    payload = if medium > 0, do: Map.put(payload, "tunnel_medium_type", medium), else: payload

    case UniCLI.HTTP.request(settings, :post, "/rest/account", payload) do
      {:ok, _} ->
        IO.puts("RADIUS user was created.")

      {:error, error} ->
        IO.puts("ERROR: could not create RADIUS user: #{error}")
    end
  end

  def delete(settings, %Optimus.ParseResult{args: %{id: id}}) do
    case UniCLI.HTTP.request(settings, :delete, "/rest/account/#{id}") do
      {:ok, _} ->
        IO.puts("User '#{id}' was deleted.")

      {:error, error} ->
        IO.puts("ERROR: could not delete user: #{error}")
    end
  end
end
