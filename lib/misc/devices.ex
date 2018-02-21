defmodule UniCLI.Misc.Devices do
  def get_device(settings, id) do
    case UniCLI.HTTP.request(settings, :get, "/stat/device") do
      {:ok, %{"data" => devices}} ->
        device = Enum.filter(devices, fn device -> device["_id"] == id end)

        if length(device) == 0 do
          {:error, "the specified device does not exist"}
        else
          {:ok, hd(device)}
        end

      {:error, error} ->
        {:error, error}
    end
  end
end
