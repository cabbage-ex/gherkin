defmodule Gherkin.Parsers.RuleParser do
  @moduledoc false

  alias Gherkin.Parsers.BackgroundParser
  alias Gherkin.Parsers.DescriptionParser
  alias Gherkin.Parsers.ScenarioParser
  alias Gherkin.Parsers.TagParser

  @doc """
  Given a Feature and the lines which form the Gherkin document, build a Rule.

  Returns the Feature with the built Rule added to its existing list of Rules.
  """
  def build_rule(rule, []), do: {%{rule | scenarios: Enum.reverse(rule.scenarios)}, []}

  def build_rule(rule, all_lines) do
    {updated_rule, remaining_lines} = DescriptionParser.build_description(rule, all_lines)
    {tags, [line | remaining_lines]} = TagParser.process_tags(remaining_lines)

    case line do
      %{text: "Background:" <> _} = _ ->
        {updated_rule, remaining_lines} =
          BackgroundParser.build_background(updated_rule, remaining_lines)

        build_rule(updated_rule, remaining_lines)

      %{text: "Scenario:" <> scenario_name, line_number: line_number} = _ ->
        build_scenario(scenario_name, line_number, tags, updated_rule, remaining_lines)

      %{text: "Example:" <> scenario_name, line_number: line_number} = _ ->
        build_scenario(scenario_name, line_number, tags, updated_rule, remaining_lines)

      %{text: "Scenario Outline:" <> scenario_name, line_number: line_number} = _ ->
        build_scenario_outline(scenario_name, line_number, tags, updated_rule, remaining_lines)

      %{text: "Scenario Template:" <> scenario_name, line_number: line_number} = _ ->
        build_scenario_outline(scenario_name, line_number, tags, updated_rule, remaining_lines)

      %{text: "Rule:" <> _} = _ ->
        {%{updated_rule | scenarios: Enum.reverse(updated_rule.scenarios)}, all_lines}

      _ ->
        raise("Unexpected line: #{line.text}")
    end
  end

  defp build_scenario(scenario_name, line_number, tags, rule, remaining_lines) do
    new_scenario = %Gherkin.Elements.Scenario{
      line: line_number,
      name: String.trim(scenario_name),
      tags: tags
    }

    {updated_scenario, remaining_lines} =
      DescriptionParser.build_description(new_scenario, remaining_lines)

    {updated_scenario, remaining_lines} =
      ScenarioParser.build_scenario(updated_scenario, remaining_lines)

    build_rule(%{rule | scenarios: [updated_scenario | rule.scenarios]}, remaining_lines)
  end

  defp build_scenario_outline(scenario_name, line_number, tags, rule, remaining_lines) do
    new_scenario_outline = %Gherkin.Elements.ScenarioOutline{
      line: line_number,
      name: String.trim(scenario_name),
      tags: tags
    }

    {updated_scenario_outline, remaining_lines} =
      DescriptionParser.build_description(new_scenario_outline, remaining_lines)

    {updated_scenario_outline, remaining_lines} =
      ScenarioParser.build_scenario_outline(updated_scenario_outline, remaining_lines)

    build_rule(%{rule | scenarios: [updated_scenario_outline | rule.scenarios]}, remaining_lines)
  end
end
