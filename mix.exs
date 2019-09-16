defmodule Gabbler.MixProject do
  use Mix.Project

  def project do
    [
      app: :gabbler,
      version: "0.1.0",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Gabbler.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4.4"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},

      {:distillery, "~> 2.1"},
      {:edeliver, "~> 1.7"},

      {:timex, "~> 3.6", override: true},
      
      {:phoenix_live_view, "~> 0.2.0"},
      {:guardian, "~> 2.0"},
      {:cachex, "~> 3.2"},
      {:thumbnex, "~> 0.3.1"},
      {:html_sanitize_ex, "~> 1.3"},
      {:cloudex, "~> 1.3"},
      {:bamboo, "~> 1.3"},
      {:recaptcha, "~> 3.0"},
      {:syn, "~> 1.6"},
      {:earmark, "~> 1.4"},
      {:simplestatex, "~> 0.3.0"},
      {:quantum, "~> 2.3"}
    ]
  end
end
