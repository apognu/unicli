defmodule UniCLI.Devices.Manage do
  def provision(settings, %Optimus.ParseResult{args: %{id: id}}) do
    with {:ok, device} <- UniCLI.Misc.Devices.get_device(settings, id) do
      case UniCLI.HTTP.request(settings, :post, "/cmd/devmgr", %{
             "cmd" => "force-provision",
             "mac" => device["mac"]
           }) do
        {:ok, _} ->
          IO.puts("Device '#{id}' is provisionning.")

        {:error, error} ->
          IO.puts("ERROR: could not set state: #{error}")
      end
    end
  else
    _ -> IO.puts("ERROR: could not find device")
  end
end
