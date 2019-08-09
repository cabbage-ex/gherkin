defmodule Gherkin.Elements.Rule do
  @moduledoc """
  Represents a single rule within a feature. Contains scenarios which demonstrate the rule.
  """
  defstruct text: "",
            description: [],
            background: nil,
            scenarios: [],
            line: 0,
            indent: 0,
            tags: []

  def update(%__MODULE__{description: []} = feature, :description, description) do
    %{feature | description: [description]}
  end

  def update(%__MODULE__{description: descriptions} = feature, :description, description) do
    %{feature | description: [description | descriptions]}
  end

  def update(%__MODULE__{scenarios: scrnarios} = feature, :scenario, scenario) do
    %{feature | scenarios: [scenario | scrnarios]}
  end

  def update(%__MODULE__{background: nil} = feature, :background, background) do
    %{feature | background: background}
  end

  def finish(%__MODULE__{scenarios: scenarios, description: description} = feature) do
    description = description |> Enum.reverse() |> Enum.join("\n") |> String.trim()
    %{feature | scenarios: Enum.reverse(scenarios), description: description}
  end
end
