defmodule Gherkin.Parsers.DescriptionParser do
  @moduledoc false

  alias Gherkin.Keywords

  def build_description(map, [line | lines] = all_lines, keywords) do
    if starts_with_keyword?(line.text, keywords) do
      {map, all_lines}
    else
      build_description(%{map | description: map.description <> line.text <> "\n"}, lines, keywords)
    end
  end

  def starts_with_keyword?(line, keywords) do
    String.starts_with?(line, ["@", ~s{"""} | Keywords.get_description_keywords_list(keywords)])
  end
end
