defmodule Gherkin.Parsers.DescriptionParser do
  @moduledoc false

  def build_description(map, [line | lines] = all_lines) do
    if starts_with_keyword?(line.text) do
      {map, all_lines}
    else
      build_description(%{map | description: map.description <> line.text <> "\n"}, lines)
    end
  end

  @all_keywords [
    "@",
    "Feature",
    "Rule",
    "Background",
    "Example",
    "Scenario",
    ~s{"""},
    "Given",
    "When",
    "Then",
    "And",
    "But"
  ]
  defp starts_with_keyword?(line) do
    String.starts_with?(line, @all_keywords)
  end
end
