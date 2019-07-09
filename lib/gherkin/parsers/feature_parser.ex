defmodule Gherkin.Parsers.FeatureParser do
  @moduledoc false

  alias Gherkin.Parsers.BackgroundParser
  alias Gherkin.Parsers.DescriptionParser
  alias Gherkin.Parsers.ScenarioParser
  alias Gherkin.Parsers.RuleParser
  alias Gherkin.Parsers.TagParser
  import Gherkin.Keywords, only: [match_keywords?: 2]
  import Gherkin.Elements.Line, only: [get_line_name: 1]

  def build_feature(feature, [], _keywords) do
    %{feature | rules: Enum.reverse(feature.rules), scenarios: Enum.reverse(feature.scenarios)}
  end

  def build_feature(feature, all_lines, keywords) do
    {tags, [line | remaining_lines]} = TagParser.process_tags(all_lines)

    cond do
      String.contains?(line.text, ["language"]) ->
        build_feature(feature, remaining_lines, keywords)

      match_keywords?(line.text, keywords.feature) ->
        updated_feature = %{
          feature |
          line: line.line_number,
          name: line.text
                |> get_line_name()
                |> String.trim(),
          tags: tags
        }
        {updated_feature, remaining_lines} = DescriptionParser.build_description(
          updated_feature,
          remaining_lines,
          keywords
        )
        build_feature(updated_feature, remaining_lines, keywords)

      match_keywords?(line.text, keywords.background) ->
        {updated_feature, remaining_lines} = BackgroundParser.build_background(feature, remaining_lines, keywords)
        build_feature(updated_feature, remaining_lines, keywords)

      match_keywords?(line.text, keywords.scenario_outline) ->
        line.text
        |> get_line_name()
        |> build_scenario_outline(line.line_number, tags, feature, remaining_lines, keywords)

      match_keywords?(line.text, keywords.scenario) ->
        line.text
        |> get_line_name()
        |> build_scenario(line.line_number, tags, feature, remaining_lines, keywords)

      match_keywords?(line.text, keywords.rule) ->
        new_rule = %Gherkin.Elements.Rule{
          line: line.line_number,
          name: line.text
                |> get_line_name()
                |> String.trim(),
          tags: tags
        }
        {updated_rule, remaining_lines} = RuleParser.build_rule(new_rule, remaining_lines, keywords)
        build_feature(%{feature | rules: [updated_rule | feature.rules]}, remaining_lines, keywords)

      true -> raise("Unexpected line when building Feature: #{line.text}")
    end
  end

  defp build_scenario(scenario_name, line_number, tags, feature, remaining_lines, keywords) do
    new_scenario = %Gherkin.Elements.Scenario{line: line_number, name: String.trim(scenario_name), tags: tags}
    {updated_scenario, remaining_lines} = ScenarioParser.build_scenario(new_scenario, remaining_lines, keywords)
    build_feature(%{feature | scenarios: [updated_scenario | feature.scenarios]}, remaining_lines, keywords)
  end

  defp build_scenario_outline(scenario_name, line_number, tags, feature, remaining_lines, keywords) do
    new_scenario_outline = %Gherkin.Elements.ScenarioOutline{
      line: line_number,
      name: String.trim(scenario_name),
      tags: tags
    }
    {updated_scenario_outline, remaining_lines} = ScenarioParser.build_scenario_outline(
      new_scenario_outline,
      remaining_lines,
      keywords
    )
    build_feature(%{feature | scenarios: [updated_scenario_outline | feature.scenarios]}, remaining_lines, keywords)
  end
end
