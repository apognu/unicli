use Mix.Config

config :elixir, ansi_enabled: true

config :unicli, UniCLI.Controller,
  profile: {:system, "UNIFI_PROFILE", "default"},
  host: {:system, "UNIFI_HOST", ""},
  username: {:system, "UNIFI_USERNAME", ""},
  password: {:system, "UNIFI_PASSWORD", ""}
