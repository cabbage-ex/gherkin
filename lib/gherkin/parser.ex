defmodule Gherkin.Parser do
  @moduledoc false
  alias Gherkin.Elements.Feature
  alias Gherkin.Keywords
  alias Gherkin.Parsers.FeatureParser

  @doc """
  Parses a string that represents a Gherkin feature document into Elixir terms.
  """
  def parse_feature(feature_text, file_name \\ nil) do
    feature_text
    |> transform_lines()
    |> normalize_lines()
    |> build_gherkin_document(file_name)
  end

  defp transform_lines(%File.Stream{line_or_bytes: :line} = file_stream) do
    transform_all_lines(file_stream)
  end

  defp transform_lines(string) do
    string
    |> String.split(~r/\r?\n/)
    # If a string, rather than a file, was given strip leading empty lines to give a more intuitive line count.
    |> Stream.drop_while(fn line -> line === "" end)
    |> transform_all_lines()
  end

  defp transform_all_lines(stream) do
    stream
    |> Stream.with_index(1)
    |> Stream.map(&transform_line/1)
  end
  
  defp transform_line({raw_line, line_number}) do
    %Gherkin.Elements.Line{raw_text: raw_line, line_number: line_number}
  end
  
  defp normalize_lines(lines) do
    lines
    |> Stream.map(&trim/1)
    # Drop empty lines and comment lines (but not language line) as nothing will be done with them
    |> Stream.filter(fn line -> line.text != "" and not Regex.match?(~r/^#(?! language)/, line.text) end)
    |> Enum.reduce([], &normalize_line/2)
    |> Enum.reverse()
  end

  defp trim(line) do
    %{line | text: String.trim_leading(line.raw_text)}
  end

  # Closing quotes for Doc String
  defp normalize_line(%{text: ~s(""") <> _} = line, {{:multiline, _}, lines}) do
    [line | lines]
  end

  # Opening quotes for Doc String
  defp normalize_line(%{text: ~s(""") <> _} = line, lines) do
    indent_length = String.length(line.raw_text) - String.length(line.text)

    {{:multiline, indent_length}, [line | lines]}
  end

  # Line between opening/closing quotes for Doc String
  defp normalize_line(line, {{:multiline, indent} = multiline_state, lines}) do
    {_, doc_string} = String.split_at(line.raw_text, indent)
    {multiline_state, [%{line | text: doc_string} | lines]}
  end

  # Default processing
  defp normalize_line(line, lines), do: [line | lines]

  defp build_gherkin_document(lines, file) do
    keywords = build_feature_keywords(List.first(lines))

    FeatureParser.build_feature(%Feature{file: file}, lines, keywords)
  end

  defp build_feature_keywords(%{text: "# language: " <> language}) do
    Keywords.get_keywords(language)
  end

  defp build_feature_keywords(_), do: Keywords.get_keywords()
end
