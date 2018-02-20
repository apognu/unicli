defmodule UniCLI.Settings do
  defstruct host: "", username: "", password: ""

  def check(settings) do
    ~w(host username password)a
    |> Enum.reduce(true, fn setting, acc ->
      acc && Map.get(settings, setting) != ""
    end)
  end
end

defmodule UniCLI do
  def main(args) do
    settings =
      with {:ok, [host: host, username: username, password: password]} <-
             Confex.fetch_env(:unicli, UniCLI.Controller) do
        settings = %UniCLI.Settings{
          host: host,
          username: username,
          password: password
        }

        unless UniCLI.Settings.check(settings) do
          IO.puts("ERROR: UNIFI_HOST, UNIFI_USERNAME and UNIFI_PASSWORD should be set")

          System.halt(1)
        end

        settings
      end

    parser =
      Optimus.new!(CLI.options())
      |> Optimus.parse!(args)

    case parser do
      {[:devices | subcommands], %Optimus.ParseResult{} = options} ->
        UniCLI.Devices.run(settings, subcommands, options)

      {[:networks | subcommands], %Optimus.ParseResult{} = options} ->
        UniCLI.Networks.run(settings, subcommands, options)

      {[:clients | subcommands], %Optimus.ParseResult{} = options} ->
        UniCLI.Clients.run(settings, subcommands, options)

      {[:vouchers | subcommands], %Optimus.ParseResult{} = options} ->
        UniCLI.Vouchers.run(settings, subcommands, options)

      _ ->
        IO.puts("ERROR: unknown command")
    end
  end
end
