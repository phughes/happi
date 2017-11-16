defmodule HAP.Mixfile do
  use Mix.Project

  def project do
    [
      app: :hap,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {HAP.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:hkdf, "~> 0.1.0"}, # Key derivation function used in pairing step M5.
      {:ed25519, "~> 1.0.2"}, # Crypto key creation.
      {:system_registry, "~> 0.6"},
      {:nerves_dnssd, "~> 0.2.0"}
    ]
  end
end
