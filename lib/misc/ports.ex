defmodule UniCLI.Misc.Ports do
  def list_configurations(settings) do
    case UniCLI.HTTP.request(settings, :get, "/rest/portconf") do
      {:ok, %{"data" => confs}} ->
        {:ok,
         confs
         |> Enum.map(fn conf ->
           %{
             id: conf["_id"],
             name: conf["attr_hidden_id"] || conf["name"]
           }
         end)}

      {:error} ->
        {:error, "could not get ports configurations"}
    end
  end

  def list_port_overrides(settings, mac) do
    case UniCLI.HTTP.request(settings, :get, "/stat/device/" <> mac) do
      {:ok, %{"data" => device}} ->
        IO.inspect(device, limit: :infinity)

        if length(device) == 0 do
          {:error, "the specified device does not exist"}
        else
          {:ok, hd(device)["port_overrides"]}
        end

      {:error} ->
        {:error}
    end
  end
end
