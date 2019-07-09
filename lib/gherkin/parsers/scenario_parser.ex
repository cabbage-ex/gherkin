defmodule Gherkin.Parsers.ScenarioParser do
  @moduledoc false

  alias Gherkin.Keywords
  alias Gherkin.Parsers.DescriptionParser
  alias Gherkin.Parsers.TableParser
  alias Gherkin.Parsers.StepParser

  def build_scenario(scenario, all_lines, keywords) do
    {updated_scenario, remaining_lines} = DescriptionParser.build_description(scenario, all_lines, keywords)
    StepParser.build_steps(updated_scenario, remaining_lines, keywords)
  end

  def build_scenario_outline(scenario_outline, all_lines, keywords) do
    {updated_scenario_outline, remaining_lines} = DescriptionParser.build_description(scenario_outline, all_lines, keywords)
    {updated_scenario_outline, [line | lines]} = StepParser.build_steps(updated_scenario_outline, remaining_lines, keywords)

    if is_examples_keyword?(line.text, keywords) do
      {[header], table_lines} = Enum.split(lines, 1)
      {kv_pairs, remaining_lines} = TableParser.parse_table(header.text, table_lines)
      {%{updated_scenario_outline | examples: kv_pairs}, remaining_lines}
    else
      raise("Unexpected line when parsing Scenario Outline: #{line.text}")
    end
  end

  defp is_examples_keyword?(text, keywords) do
    Keywords.match_keywords?(text, keywords.examples)
  end
end
