# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

if Mix.Project.config[:target] == "host" do
   config :hap, data_path: "/tmp"
else
   config :hap, data_path: "/root"
end

config :system_registry, SystemRegistry.TermStorage,
  scopes: [
    [:state, :hap, :config],
  ]

config :hap, HAP.Pairing.Impl,
  user_partition: "/Users/pat"