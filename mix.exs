defmodule FSModEvent.Mixfile do
  use Mix.Project

  def project do
    [
      app: :elixir_mod_event,
      name: "elixir_mod_event",
      version: "0.0.6",
      description: description,
      package: package,
      source_url: "https://github.com/marcelog/elixir_mod_event",
      elixir: "~> 1.0",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps
    ]
  end

  def application do
    [
      applications: [:logger]
    ]
  end

  defp description do
    """
Elixir client for FreeSWITCH mod_event_socket.

Find the user guide in the github repo at: https://github.com/marcelog/elixir_mod_event.
    """
  end

  defp package do
    [
      files: ["lib", "priv", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Marcelo Gornstein"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/marcelog/elixir_mod_event"
      }
    ]
  end

  defp deps do
    [
      {:earmark, "~> 0.2.1", only: :dev},
      {:ex_doc, "~> 0.12.0", only: :dev},
      {:coverex, "~> 1.4.9", only: :test},
      {:uuid, "~> 1.1.4"}
    ]
  end
end
