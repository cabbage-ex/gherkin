defmodule Gherkin.Parsers.BackgroundParser do
  @moduledoc false

  alias Gherkin.Parsers.DescriptionParser
  alias Gherkin.Parsers.StepParser

  def build_background(map, all_lines) do
    {map, remaining_lines} = DescriptionParser.build_description(map, all_lines)
    StepParser.build_background_steps(map, remaining_lines)
  end
end
