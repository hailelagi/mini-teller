import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :mini_teller, MiniTeller.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "mini_teller_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mini_teller, MiniTellerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "kWzbJRo1t8edIwgUFiyhxKuqJ7LuNZbFKQxVKWEf+lldZKHyqm0b4GQSsh5ZjMX4",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :mini_teller,
  client: MiniTeller.Mock,
  base_url: nil,
  api_key: nil,
  username: nil,
  password: nil
