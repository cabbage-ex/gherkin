defmodule Gherkin.Mixfile do
  use Mix.Project

  @version "1.6.0"
  def project do
    [
      app: :gherkin,
      version: @version,
      elixir: "~> 1.3",
      source_url: "git@github.com:cabbage-ex/gherkin.git",
      homepage_url: "https://github.com/cabbage-ex/gherkin",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: "Gherkin file parser for Elixir",
      docs: [
        main: Gherkin,
        readme: "README.md"
      ],
      package: package(),
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ex_doc, "~> 0.18", only: :dev},
      {:earmark, "~> 1.2", only: :dev}
    ]
  end

  defp package do
    [
      maintainers: ["Matt Widmann", "Steve B"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/cabbage-ex/gherkin"}
    ]
  end

  defp aliases do
    [publish: ["hex.publish", "hex.publish docs", "tag"],
     tag: &tag_release/1]
  end

  defp tag_release(_) do
    Mix.shell.info "Tagging release as #{@version}"
    System.cmd("git", ["tag", "-a", "v#{@version}", "-m", "v#{@version}"])
    System.cmd("git", ["push", "--tags"])
  end
end
