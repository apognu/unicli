defmodule UniCLI.Clients.Guests do
  def run(settings, subcommands, options) do
    case subcommands do
      [:authorize] -> set_state(settings, true, options)
      [:unauthorize] -> set_state(settings, false, options)
    end
  end

  def set_state(settings, state, %Optimus.ParseResult{args: %{mac: client_mac}}) do
    cmd = if state, do: "authorize-guest", else: "unauthorize-guest"

    case UniCLI.HTTP.request(settings, :post, "/cmd/stamgr", %{
           "cmd" => cmd,
           "mac" => client_mac
         }) do
      {:ok, _} ->
        if state do
          IO.puts("Client '#{client_mac}' was authorized.")
        else
          IO.puts("Client '#{client_mac}' was unauthorized.")
        end

      {:error, error} ->
        IO.puts("ERROR: could not set state: #{error}")
    end
  end
end
