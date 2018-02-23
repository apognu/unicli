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
          IO.puts("ERROR: could not provision device: #{error}")
      end
    else
      _ -> IO.puts("ERROR: could not find device")
    end
  end

  def restart(settings, %Optimus.ParseResult{args: %{id: id}}) do
    with {:ok, device} <- UniCLI.Misc.Devices.get_device(settings, id) do
      case UniCLI.HTTP.request(settings, :post, "/cmd/devmgr", %{
             "cmd" => "restart",
             "reboot_type" => "soft",
             "mac" => device["mac"]
           }) do
        {:ok, _} ->
          IO.puts("Device '#{id}' is restarting.")

        {:error, error} ->
          IO.puts("ERROR: could not restart device: #{error}")
      end
    else
      _ -> IO.puts("ERROR: could not find device")
    end
  end

  def adopt(settings, %Optimus.ParseResult{args: %{mac: mac}}) do
    case UniCLI.HTTP.request(settings, :post, "/cmd/devmgr", %{
           "cmd" => "adopt",
           "mac" => mac
         }) do
      {:ok, _} ->
        IO.puts("Device '#{mac}' is being adopted.")

      {:error, error} ->
        IO.puts("ERROR: could not adopt device: #{error}")
    end
  end
end
