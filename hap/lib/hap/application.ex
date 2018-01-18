defmodule HAP.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    Logger.warn "### Starting HAP.Application ###"
    HAP.Pairing.Impl.setup()

    # List all child processes to be supervised
    children = [
      {HAP.Bonjour, name: HAP.Bonjour},
      {HAP.Pairing, name: HAP.Pairing},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HAP.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
