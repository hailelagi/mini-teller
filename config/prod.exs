import Config

config :mini_teller, MiniTellerWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

# Do not print debug messages in production
config :logger, level: :info

config :mini_teller,
  client: MiniTeller.Live,
  base_url: System.get_env("BASE_URL"),
  api_key: System.get_env("API_KEY"),
  device_id: System.get_env("DEVICE_ID"),
