defmodule ReleaseBuild.Mixfile do
  use Mix.Project

  def project do
    [
      app: :release_build,
      description: "Build elixir release tar from inside a docker container",
      source_url: "https://github.com/shareup/release_build",
      homepage_url: "https://github.com/shareup/release_build#readme",
      version: "0.5.0",
      elixir: "~> 1.9",
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/shareup/release_build"
      }
    ]
  end
end
