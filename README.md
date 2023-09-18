# Gherkin [![Hex.pm](https://img.shields.io/hexpm/v/gherkin.svg)](https://hex.pm/packages/gherkin)

[![Coverage Status](https://coveralls.io/repos/github/cabbage-ex/gherkin/badge.svg?branch=master)](https://coveralls.io/github/cabbage-ex/gherkin?branch=master)
[![CircleCI](https://circleci.com/gh/cabbage-ex/gherkin.svg?style=svg)](https://circleci.com/gh/cabbage-ex/gherkin)

A Gherkin file parser written in Elixir. Parses `.feature` files and translates them to native Elixir terms for processing.

Extracted from https://github.com/meadsteve/white-bread

## Installation

The package can be installed as:

```elixir
def deps do
  [{:gherkin, "~> 2.0"}]
end
```

## Example Usage

```elixir
%Gherkin.Elements.Feature{scenarios: scenarios} = File.read!("test/features/coffee.feature") |> Gherkin.parse()
# Do something with `scenarios`

# Also supports file streams for larger files (must read by lines, bytes not supported)
%Gherkin.Elements.Feature{scenarios: scenarios} = File.stream!("test/features/coffee.feature") |> Gherkin.parse()
```
