defmodule Gherkin.Parsers.StepParser do
  @moduledoc false

  alias Gherkin.Elements.Step
  alias Gherkin.Parsers.TableParser
  alias Gherkin.Parsers.DocStringParser

  def build_background_steps(map, all_lines) do
    {steps, remaining_lines} = parse_steps(all_lines)
    {%{map | background_steps: steps}, remaining_lines}
  end

  def build_steps(map, all_lines) do
    {steps, remaining_lines} = parse_steps(all_lines)
    {%{map | steps: steps}, remaining_lines}
  end

  defp parse_steps(steps \\ [], lines)
  defp parse_steps(steps, []), do: {Enum.reverse(steps), []}

  defp parse_steps(all_steps, [line | lines] = all_lines) do
    part_list = String.split(line.text, " ", parts: 2)

    if is_step?(List.first(part_list)) do
      new_step = %Step{
        keyword: List.first(part_list),
        text: List.last(part_list),
        line: line.line_number
      }

      parse_steps([new_step | all_steps], lines)
    else
      [step | steps] = all_steps

      case line.text do
        "|" <> text ->
          {kv_pairs, remaining_lines} = TableParser.parse_table(text, lines)
          parse_steps([%{step | table_data: kv_pairs} | steps], remaining_lines)

        ~s(""") <> _ ->
          {updated_step, remaining_lines} = DocStringParser.parse_doc_string(step, lines)
          parse_steps([updated_step | steps], remaining_lines)

        _ ->
          {Enum.reverse(all_steps), all_lines}
      end
    end
  end

  defp is_step?(keyword) do
    keyword in ["Given", "Then", "When", "And", "But"]
  end
end
