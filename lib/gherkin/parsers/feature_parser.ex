defmodule Gherkin.Parsers.FeatureParser do
  @moduledoc false

  alias Gherkin.Parsers.BackgroundParser
  alias Gherkin.Parsers.DescriptionParser
  alias Gherkin.Parsers.ScenarioParser
  alias Gherkin.Parsers.RuleParser
  alias Gherkin.Parsers.TagParser

  def build_feature(feature, []) do
    %{feature | rules: Enum.reverse(feature.rules), scenarios: Enum.reverse(feature.scenarios)}
  end

  def build_feature(feature, all_lines) do
    {tags, [line | remaining_lines]} = TagParser.process_tags(all_lines)

    case line do
      %{text: "Feature: " <> name, line_number: line_number} = _ ->
        updated_feature = %{feature | line: line_number, name: String.trim(name), tags: tags}

        {updated_feature, remaining_lines} =
          DescriptionParser.build_description(updated_feature, remaining_lines)

        build_feature(updated_feature, remaining_lines)

      %{text: "Background:" <> _} = _ ->
        {updated_feature, remaining_lines} =
          BackgroundParser.build_background(feature, remaining_lines)

        build_feature(updated_feature, remaining_lines)

      %{text: "Scenario:" <> scenario_name, line_number: line_number} = _ ->
        build_scenario(scenario_name, line_number, tags, feature, remaining_lines)

      %{text: "Example:" <> scenario_name, line_number: line_number} = _ ->
        build_scenario(scenario_name, line_number, tags, feature, remaining_lines)

      %{text: "Scenario Outline:" <> scenario_name, line_number: line_number} = _ ->
        build_scenario_outline(scenario_name, line_number, tags, feature, remaining_lines)

      %{text: "Scenario Template:" <> scenario_name, line_number: line_number} = _ ->
        build_scenario_outline(scenario_name, line_number, tags, feature, remaining_lines)

      %{text: "Rule:" <> rule_name, line_number: line_number} = _ ->
        new_rule = %Gherkin.Elements.Rule{
          line: line_number,
          name: String.trim(rule_name),
          tags: tags
        }

        {updated_rule, remaining_lines} = RuleParser.build_rule(new_rule, remaining_lines)
        build_feature(%{feature | rules: [updated_rule | feature.rules]}, remaining_lines)

      _ ->
        raise("Unexpected line when building Feature: #{line.text}")
    end
  end

  defp build_scenario(scenario_name, line_number, tags, feature, remaining_lines) do
    new_scenario = %Gherkin.Elements.Scenario{
      line: line_number,
      name: String.trim(scenario_name),
      tags: tags
    }

    {updated_scenario, remaining_lines} =
      ScenarioParser.build_scenario(new_scenario, remaining_lines)

    build_feature(%{feature | scenarios: [updated_scenario | feature.scenarios]}, remaining_lines)
  end

  defp build_scenario_outline(scenario_name, line_number, tags, feature, remaining_lines) do
    new_scenario_outline = %Gherkin.Elements.ScenarioOutline{
      line: line_number,
      name: String.trim(scenario_name),
      tags: tags
    }

    {updated_scenario_outline, remaining_lines} =
      ScenarioParser.build_scenario_outline(new_scenario_outline, remaining_lines)

    build_feature(
      %{feature | scenarios: [updated_scenario_outline | feature.scenarios]},
      remaining_lines
    )
  end
end
