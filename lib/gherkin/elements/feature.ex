defmodule Gherkin.Elements.Feature do
  @moduledoc """
  Representation of an entire feature. Contains rules and/or scenarios which are the primary focus of the feature.
  """
  defstruct text: "",
            description: [],
            tags: [],
            background: nil,
            rules: [],
            scenarios: [],
            line: 0,
            indent: 0,
            file: nil

  def update(%__MODULE__{description: []} = feature, :description, description) do
    %{feature | description: [description]}
  end

  def update(%__MODULE__{description: descriptions} = feature, :description, description) do
    %{feature | description: [description | descriptions]}
  end

  def update(%__MODULE__{rules: rules} = feature, :rule, rule) do
    %{feature | rules: [rule | rules]}
  end

  def update(%__MODULE__{scenarios: scrnarios} = feature, :scenario, scenario) do
    %{feature | scenarios: [scenario | scrnarios]}
  end

  def update(%__MODULE__{scenarios: scrnarios} = feature, :scenario_outline, scenario_outline) do
    %{feature | scenarios: [scenario_outline | scrnarios]}
  end

  def update(%__MODULE__{background: nil} = feature, :background, background) do
    %{feature | background: background}
  end

  def finish(%__MODULE__{scenarios: scenarios, description: description} = feature) do
    description = description |> Enum.reverse() |> Enum.join("\n") |> String.trim()
    %{feature | scenarios: Enum.reverse(scenarios), description: description}
  end
end
