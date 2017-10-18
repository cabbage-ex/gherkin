defmodule Gherkin.Parser.GenericLine do
  @moduledoc false
  require Logger
  alias Gherkin.Parser.Helpers.Feature, as: FeatureParser
  alias Gherkin.Parser.Helpers.Scenario, as: ScenarioParser
  alias Gherkin.Parser.Helpers.Steps, as: StepsParser
  alias Gherkin.Parser.Helpers.Tables, as: TableParser
  alias Gherkin.Parser.Helpers.DocString, as: DocStringParser

  def process_line({line, line_number}, state) do
    line
      |> log
      |> process(state, line_number)
  end

  defp process("", state, _line_number) do
    state
  end

  defp process("#" <> _comment, state, _line_number) do
    state
  end

  defp process("@" <> line, {feature, %{tags: tags}}, _line_number) do
    {feature, %{tags: tags ++ process_tags(line)}}
  end

  defp process("@" <> line, {feature, _state}, _line_number) do
    {feature, %{tags: process_tags(line)}}
  end

  defp process("Feature: " <> name, {feature, state}, line_number) do
    feature_tags = tags_from_state(state)
    FeatureParser.start_processing_feature(feature, name, feature_tags, line_number)
  end

  defp process("Background:" <> _, {feature, _}, _line_number) do
    {feature, :background_steps}
  end

  defp process("Examples:" <> _, {feature, _}, _line_number) do
    {feature, {:scenario_outline_example, []}}
  end

  defp process("Scenario: " <> name, {feature, state}, line_number) do
    tags = tags_from_state(state)
    ScenarioParser.start_processing_scenario(feature, name, tags, line_number)
  end

  defp process("Scenario Outline: " <> name, {feature, state}, line_number) do
    tags = tags_from_state(state)
    ScenarioParser.start_processing_scenario_outline(feature, name, tags, line_number)
  end

  # Stop recoding doc string
  defp process(~s(""") <> _, {feature, {:doc_string, prev_state}}, _line_number) do
    DocStringParser.stop_processing_doc_string(feature, prev_state)
  end

  # Start recoding doc string
  defp process(~s(""") <> _, {feature, state}, _line_number) do
    DocStringParser.start_processing_doc_string(feature, state)
  end

  defp process(line, {feature, {:doc_string, :background_steps} = state}, _line_number) do
    DocStringParser.process_background_step_doc_string(line, feature, state)
  end

  defp process(line, {feature, { :doc_string, _prev_state } = state}, _line_number) do
    DocStringParser.process_scenario_step_doc_string(line, feature, state)
  end

  # Tables as part of a step
  defp process("|" <> line, {feature, {:scenario_steps, keys}}, _line_number) do
    TableParser.process_step_table_line(line, feature, keys)
  end

  # Tables as part of an example for a scenario
  defp process("|" <> line, {feature, {:scenario_outline_example, keys}}, _line_number) do
    TableParser.process_outline_table_line(line, feature, keys)
  end

  defp process(line, {feature, :feature_description}, _line_number) do
    FeatureParser.process_feature_desc_line(line, feature)
  end

  defp process(line, {feature, :background_steps}, line_number) do
    StepsParser.process_background_step_line(line, feature, line_number)
  end

  defp process(line, {feature, {:scenario_steps, _}}, line_number) do
    StepsParser.process_scenario_step_line(line, feature, line_number)
  end

  defp process(_line, state, _line_number) do
    state
  end

  defp process_tags(line) do
    line
    |> String.split("@", trim: true)
    |> Enum.map(&process_tag/1)
  end

  defp process_tag(tag) do
    case tag |> String.trim() |> String.split(" ") do
      [t] -> String.to_atom(t)
      [t, v] ->
        case Float.parse(v) do
          {num, ""} ->
            # Convert from float to int if it is exactly
            num = if Float.floor(num) == num, do: round(num), else: num
            {String.to_atom(t), num}
          :error ->
            {String.to_atom(t), v}
        end
    end
  end

  defp log(line) do
    Logger.debug(~s(Parsing line: "#{line}"))
    line
  end

  defp tags_from_state(%{tags: tags}), do: tags
  defp tags_from_state(_), do: []

end
