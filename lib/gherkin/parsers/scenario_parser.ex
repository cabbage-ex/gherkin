defmodule Gherkin.Parsers.ScenarioParser do
  @moduledoc false

  alias Gherkin.Parsers.DescriptionParser
  alias Gherkin.Parsers.TableParser
  alias Gherkin.Parsers.StepParser

  def build_scenario(scenario, all_lines) do
    {updated_scenario, remaining_lines} = DescriptionParser.build_description(scenario, all_lines)
    StepParser.build_steps(updated_scenario, remaining_lines)
  end

  def build_scenario_outline(scenario_outline, all_lines) do
    {updated_scenario_outline, remaining_lines} =
      DescriptionParser.build_description(scenario_outline, all_lines)

    {updated_scenario_outline, [line | lines]} =
      StepParser.build_steps(updated_scenario_outline, remaining_lines)

    if is_outline_keyword?(line.text) do
      {[header], table_lines} = Enum.split(lines, 1)
      {kv_pairs, remaining_lines} = TableParser.parse_table(header.text, table_lines)
      {%{updated_scenario_outline | examples: kv_pairs}, remaining_lines}
    else
      raise("Unexpected line when parsing Scenario Outline: #{line.text}")
    end
  end

  defp is_outline_keyword?(text) do
    String.trim(text) in ["Examples:", "Scenarios:"]
  end
end
