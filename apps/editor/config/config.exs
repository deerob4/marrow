# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :editor,
  ecto_repos: [Editor.Repo]

# Configures the endpoint
config :editor, EditorWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "HgsHvIlB05ep+9mGIh7gP+XS773evL7BI/FlyswQ+Nm6KVwr7uesQu/jLPA9I8G0",
  render_errors: [view: EditorWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Editor.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ex_aws,
  region: "eu-west-2",
  debug_requests: true,
  access_key_id: "AKIAJTDIP5ITBI5TPGNA",
  secret_key_id: "th09n8c6k372TXP68XC187uMpzR9h"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
