# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

if Mix.Project.config()[:target] == "host" do
  config :hap, data_path: "/tmp"
else
  config :hap, data_path: "/root"
end

config :system_registry, SystemRegistry.TermStorage,
  scopes: [
    [:state, :hap, :config]
  ]

# Configures the endpoint
config :hap, HapWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "h1gMIYiwan8SDRUGOeHCTeE8VfwqrRZJfrZY+QLG+rkAL3YE2BL1GbA1YF62i0/E",
  render_errors: [view: HapWeb.ErrorView, accepts: ~w(html json)],
  code_reloader: true,
  pubsub: [name: Hap.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
