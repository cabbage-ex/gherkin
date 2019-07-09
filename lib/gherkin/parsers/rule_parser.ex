defmodule Gherkin.Parsers.RuleParser do
  @moduledoc false

  alias Gherkin.Parsers.BackgroundParser
  alias Gherkin.Parsers.DescriptionParser
  alias Gherkin.Parsers.ScenarioParser
  alias Gherkin.Parsers.TagParser
  import Gherkin.Keywords, only: [match_keywords?: 2]
  import Gherkin.Elements.Line, only: [get_line_name: 1]

  @doc """
  Given a Feature and the lines which form the Gherkin document, build a Rule.

  Returns the Feature with the built Rule added to its existing list of Rules.
  """
  def build_rule(rule, [], _keywords), do: {%{rule | scenarios: Enum.reverse(rule.scenarios)}, []}
  def build_rule(rule, all_lines, keywords) do
    {updated_rule, remaining_lines} = DescriptionParser.build_description(rule, all_lines, keywords)
    {tags, [line | remaining_lines]} = TagParser.process_tags(remaining_lines)

    cond do
      match_keywords?(line.text, keywords.background) ->
        {updated_rule, remaining_lines} = BackgroundParser.build_background(updated_rule, remaining_lines, keywords)
        build_rule(updated_rule, remaining_lines, keywords)

      match_keywords?(line.text, keywords.scenario) ->
        line.text
        |> get_line_name()
        |> build_scenario(line.line_number, tags, updated_rule, remaining_lines, keywords)

      match_keywords?(line.text, keywords.scenario_outline) ->
        line.text
        |> get_line_name()
        |> build_scenario_outline(line.line_number, tags, updated_rule, remaining_lines, keywords)

      match_keywords?(line.text, keywords.rule) ->
        {%{updated_rule | scenarios: Enum.reverse(updated_rule.scenarios)}, all_lines}

      true -> raise("Unexpected line: #{line.text}")
    end
  end

  defp build_scenario(scenario_name, line_number, tags, rule, remaining_lines, keywords) do
    new_scenario = %Gherkin.Elements.Scenario{line: line_number, name: String.trim(scenario_name), tags: tags}
    {updated_scenario, remaining_lines} = DescriptionParser.build_description(new_scenario, remaining_lines, keywords)
    {updated_scenario, remaining_lines} = ScenarioParser.build_scenario(updated_scenario, remaining_lines, keywords)
    build_rule(%{rule | scenarios: [updated_scenario | rule.scenarios]}, remaining_lines, keywords)
  end

  defp build_scenario_outline(scenario_name, line_number, tags, rule, remaining_lines, keywords) do
    new_scenario_outline = %Gherkin.Elements.ScenarioOutline{line: line_number, name: String.trim(scenario_name), tags: tags}
    {updated_scenario_outline, remaining_lines} = DescriptionParser.build_description(new_scenario_outline, remaining_lines, keywords)
    {updated_scenario_outline, remaining_lines} = ScenarioParser.build_scenario_outline(updated_scenario_outline, remaining_lines, keywords)
    build_rule(%{rule | scenarios: [updated_scenario_outline | rule.scenarios]}, remaining_lines, keywords)
  end
end
