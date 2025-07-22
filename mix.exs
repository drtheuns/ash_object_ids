defmodule AshObjectIds.MixProject do
  use Mix.Project

  @description """
  An Ash extension to use object IDs as primary and foreign keys.
  """

  @version "0.1.0"

  @project_url "https://github.com/drtheuns/ash_object_ids"

  def project do
    [
      app: :ash_object_ids,
      version: @version,
      package: package(),
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: @description,
      source_url: @project_url,
      homepage_url: @project_url,
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      name: :ash_object_ids,
      licenses: ["MIT"],
      files: ["lib", ".formatter", "mix.exs", "README*", "LICENSE*"],
      links: %{
        GitHub: @project_url
      }
    ]
  end

  defp deps do
    [
      {:ash, "~> 3.0"},
      {:erl_base58, "~> 0.0.1"}
    ]
  end
end
