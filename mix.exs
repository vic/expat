defmodule Expat.MixProject do
  use Mix.Project

  def project do
    [
      app: :expat,
      version: "1.0.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      name: "Expat",
      description: "Re-usable composable patterns with guards",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      docs: [
        main: "Expat"
      ],
      deps: deps()
    ]
  end

  defp package do
    [
      maintainers: ["Victor Borja <vborja@apache.org>"],
      licenses: ["Apache-2"],
      links: %{"GitHub" => "https://github.com/vic/expat"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.0", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
