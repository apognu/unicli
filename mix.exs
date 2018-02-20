defmodule Unicli.MixProject do
  use Mix.Project

  def project do
    [
      app: :unicli,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      escript: [
        main_module: UniCLI,
        embed_elixir: true
      ],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [
        :logger,
        :confex,
        :tesla,
        :timex,
        :table_rex
      ]
    ]
  end

  defp deps do
    [
      {:confex, "~> 3.3.1"},
      {:optimus, "~> 0.1"},
      {:bunt, "~> 0.2"},
      {:tableize, "~> 0.1"},
      {:table_rex, "~> 0.10"},
      {:tesla, github: "teamon/tesla", branch: "1.0"},
      {:poison, ">= 1.0.0"},
      {:timex, "~> 3.1"},
      {:tzdata, "~> 0.1.8", override: true},
      {:size, "~> 0.1.0"}
    ]
  end
end
