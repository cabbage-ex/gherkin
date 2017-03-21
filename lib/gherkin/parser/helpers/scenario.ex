defmodule Gherkin.Parser.Helpers.Scenario do
  @moduledoc false
  alias Gherkin.Elements.Scenario
  alias Gherkin.Elements.ScenarioOutline

  def start_processing_scenario(feature, name, tags, line) do
    previous_scenarios = feature.scenarios
    new_scenario = %Scenario{name: name, tags: tags, line: line}
    {
      %{feature | scenarios: [new_scenario | previous_scenarios]},
      {:scenario_steps, []}
    }
  end

  def start_processing_scenario_outline(feature, name, tags, line) do
    previous_scenarios = feature.scenarios
    new_scenario_outline = %ScenarioOutline{name: name, tags: tags, line: line}
    {
      %{feature | scenarios: [new_scenario_outline | previous_scenarios]},
      {:scenario_steps, []}
    }
  end

end
