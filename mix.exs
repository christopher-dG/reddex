defmodule Reddex.MixProject do
  use Mix.Project

  def project do
    [
      app: :reddex,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Reddex.Application, []}
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:hackney, "~> 1.14"},
      {:jason, "~> 1.1"},
      {:tesla, "~> 1.2"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_url: "https://github.com/christopher-dG/reddex"
    ]
  end
end
