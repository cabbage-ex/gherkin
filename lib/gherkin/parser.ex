defmodule Gherkin.Parser do
  @moduledoc false
  alias Gherkin.Elements.Feature, as: Feature
  alias Gherkin.Parser.GenericLine, as: LineParser
  alias Gherkin.Elements.Scenario
  alias Gherkin.Elements.ScenarioOutline

  def parse_feature(feature_text) do
    feature_text
    |> process_lines
    |> parse_each_line
    |> correct_scenario_order
    |> migrate_scenario_outline_examples
  end

  defp correct_scenario_order(feature = %{scenarios: scenarios}) do
    %{feature | scenarios: Enum.reverse(scenarios)}
  end

  defp migrate_scenario_outline_examples(feature = %{scenarios: scenarios}) do
    %{feature | scenarios: Enum.map(scenarios, &migrate_scenario_outline/1)}
  end

  defp migrate_scenario_outline(scenario = %Scenario{}), do: scenario
  defp migrate_scenario_outline(outline = %ScenarioOutline{examples: [header | data]}) do
    header = Enum.map(header, &String.to_atom/1)
    %{outline | examples: Enum.map(data, &(header |> Enum.zip(&1) |> Enum.into(%{})))}
  end

  def process_lines(%File.Stream{line_or_bytes: :line} = stream) do
    {:ok, output} = Enum.reduce(stream, {:ok, []}, &process_line/2)

    Enum.reverse(output)
  end
  def process_lines(string) do
    {:ok, output} =
      string |> String.split(~r/\r?\n/)
             |> Enum.reduce({:ok, []}, &process_line/2)

    Enum.reverse(output)
  end

  defp process_line(line, {state, lines}) do
    process_line(String.lstrip(line), {state, lines, line})
  end

  # Multiline / Doc string processing
  defp process_line(line = ~s(""") <> _, {:ok, lines, original_line}) do
    indent_length = String.length(original_line) -
                    String.length(String.lstrip(original_line))
    {{:multiline, indent_length}, [ line | lines ]}
  end
  defp process_line(line = ~s(""") <> _, {{:multiline, _}, lines, _}) do
    {:ok, [ line | lines ]}
  end
  defp process_line(_, {{:multiline, indent} = state, lines, original_line}) do
    {strippable, doc_string} = String.split_at(original_line, indent)
    {state, [ String.lstrip(strippable) <> doc_string | lines ]}
  end

  # Default processing
  defp process_line(line, {:ok, lines, _}), do: {:ok, [ line | lines ]}

  defp parse_each_line(lines) do
    {feature, _end_state} = lines
      |> Enum.with_index(1)
      |> Enum.reduce({%Feature{}, :start}, &LineParser.process_line/2)
    feature
  end

end
