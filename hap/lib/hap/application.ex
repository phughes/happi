defmodule HAP.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    HAP.Pairing.Impl.setup()

    # List all child processes to be supervised
    children = [
      # Start the endpoint when the application starts
      HapWeb.Endpoint,
      # Starts a worker by calling: Hap.Worker.start_link(arg)
      {HAP.Pairing, name: HAP.Pairing}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HAP.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    HapWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
