defmodule Gherkin.Parser do
  @moduledoc false
  alias Gherkin.Elements.Feature, as: Feature
  alias Gherkin.Parser.GenericLine, as: LineParser

  def parse_feature(feature_text, file_name \\ nil) do
    feature_text
    |> process_lines()
    |> parse_each_line(file_name)
    |> correct_scenario_order()
  end

  defp correct_scenario_order(feature = %{scenarios: scenarios}) do
    %{feature | scenarios: Enum.reverse(scenarios)}
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
    process_line(String.trim_leading(line), {state, lines, line})
  end

  # Multiline / Doc string processing
  defp process_line(line = ~s(""") <> _, {:ok, lines, original_line}) do
    indent_length = String.length(original_line) -
                    String.length(String.trim_leading(original_line))
    {{:multiline, indent_length}, [ line | lines ]}
  end
  defp process_line(line = ~s(""") <> _, {{:multiline, _}, lines, _}) do
    {:ok, [ line | lines ]}
  end
  defp process_line(_, {{:multiline, indent} = state, lines, original_line}) do
    {strippable, doc_string} = String.split_at(original_line, indent)
    {state, [ String.trim_leading(strippable) <> doc_string | lines ]}
  end

  # Default processing
  defp process_line(line, {:ok, lines, _}), do: {:ok, [ line | lines ]}

  defp parse_each_line(lines, file) do
    {feature, _end_state} = lines
      |> Enum.with_index(1)
      |> Enum.reduce({%Feature{file: file}, :start}, &LineParser.process_line/2)
    feature
  end

end
