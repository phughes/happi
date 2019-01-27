defmodule HAP.Mixfile do
  use Mix.Project

  def project do
    [
      app: :hap,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
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
      # Key derivation function used in pairing step M5.
      {:hkdf, "~> 0.1.0"},
      {:salty, "~> 0.1.3", hex: :libsalty},
      {:system_registry, "~> 0.8"},
      {:nerves_dnssd, git: "https://github.com/amolenaar/nerves_dnssd"}
    ]
  end
end
