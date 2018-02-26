defmodule UniCLI.Settings do
  defstruct host: "", username: "", password: "", site: "default", directory: nil

  def check(settings) do
    if settings.host == "https://demo.ubnt.com" do
      true
    else
      ~w(host username password)a
      |> Enum.reduce(true, fn setting, acc ->
        acc && Map.get(settings, setting) != ""
      end)
    end
  end
end

defmodule UniCLI do
  def main(args) do
    directory =
      case create_homedir() do
        {:ok, directory} ->
          directory

        {:error, message} ->
          IO.puts("WARNING: #{message}")

          nil
      end

    settings =
      with {:ok, [host: host, username: username, password: password]} <-
             Confex.fetch_env(:unicli, UniCLI.Controller) do
        settings = %UniCLI.Settings{
          host: host,
          username: username,
          password: password,
          directory: directory
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

    site =
      case parser do
        {_, %Optimus.ParseResult{options: %{site: site}}} -> site
        _ -> "default"
      end

    settings = %{settings | site: site}

    case parser do
      {[:sites | subcommands], options} ->
        UniCLI.Util.sites(settings, subcommands, options)

      {[:devices | subcommands], %Optimus.ParseResult{} = options} ->
        UniCLI.Devices.run(settings, subcommands, options)

      {[:networks | subcommands], %Optimus.ParseResult{} = options} ->
        UniCLI.Networks.run(settings, subcommands, options)

      {[:clients | subcommands], %Optimus.ParseResult{} = options} ->
        UniCLI.Clients.run(settings, subcommands, options)

      {[:vouchers | subcommands], %Optimus.ParseResult{} = options} ->
        UniCLI.Vouchers.run(settings, subcommands, options)

      {[:radius | subcommands], %Optimus.ParseResult{} = options} ->
        UniCLI.RADIUS.run(settings, subcommands, options)

      {[:events | subcommands], options} ->
        UniCLI.Events.Events.run(settings, subcommands, options)

      {[:alerts | subcommands], options} ->
        UniCLI.Events.Alerts.run(settings, subcommands, options)

      _ ->
        IO.puts("ERROR: unknown command")
    end
  end

  def create_homedir() do
    with {:ok, home} <- UniCLI.Util.env("HOME"),
         :ok <- File.mkdir_p("#{home}/.unicli") do
      {:ok, "#{home}/.unicli"}
    else
      _ -> {:error, "could not create ~/.unicli"}
    end
  end
end
