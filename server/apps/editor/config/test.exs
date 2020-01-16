use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :editor, EditorWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :editor, Editor.Repo,
  username: System.get_env("MARROW_DB_USERNAME"),
  password: System.get_env("MARROW_DB_PASSWORD"),
  database: "editor_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
