# Gherkin [![Hex.pm](https://img.shields.io/hexpm/v/gherkin.svg)]()

A Gherkin file parser written in Elixir. Parses `.feature` files and translates them to native Elixir terms for processing.

Extracted from https://github.com/meadsteve/white-bread

## Installation

The package can be installed as:

  1. Add `gherkin` to your list of dependencies in `mix.exs`:


```elixir
def deps do
  [{:gherkin, "~> 1.0"}]
end
```

  2. Ensure `gherkin` is started before your application:

```elixir
def application do
  [applications: [:gherkin]]
end
```

## Example Usage

```elixir
%Gherkin.Elements.Feature{scenarios: scenarios} = File.read!("test/features/coffee.feature") |> Gherkin.parse()
# Do something with `scenarios`

# Also supports file streams for larger files (must read by lines, bytes not supported)
%Gherkin.Elements.Feature{scenarios: scenarios} = File.stream!("test/features/coffee.feature") |> Gherkin.parse()
```
