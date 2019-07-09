defmodule Gherkin.Parsers.StepParser do
  @moduledoc false

  alias Gherkin.Keywords
  alias Gherkin.Elements.Step
  alias Gherkin.Parsers.TableParser
  alias Gherkin.Parsers.DocStringParser

  def build_background_steps(map, all_lines, keywords) do
    {steps, remaining_lines} = parse_steps(all_lines, keywords)
    {%{map | background_steps: steps}, remaining_lines}
  end

  def build_steps(map, all_lines, keywords) do
    {steps, remaining_lines} = parse_steps(all_lines, keywords)
    {%{map | steps: steps}, remaining_lines}
  end

  defp parse_steps(steps \\ [], lines, keywords)
  defp parse_steps(steps, [], _keywords), do: {Enum.reverse(steps), []}
  defp parse_steps(all_steps, [line | lines] = all_lines, keywords) do
    step_keywords_list = Keywords.get_step_keywords_list(keywords)
    keyword = Keywords.find_keyword_from_list(line.text, step_keywords_list)

    if nil !== keyword do
      text = line.text
             |> String.replace_prefix(keyword, "")
             |> String.trim
      new_step = %Step{keyword: keyword, text: text, line: line.line_number}
      parse_steps([new_step | all_steps], lines, keywords)
    else
      [step | steps] = all_steps
      case line.text do
        "|" <> text ->
          {kv_pairs, remaining_lines} = TableParser.parse_table(text, lines)
          parse_steps([%{step | table_data: kv_pairs} | steps], remaining_lines, keywords)
        ~s(""") <> _ ->
          {updated_step, remaining_lines} = DocStringParser.parse_doc_string(step, lines)
          parse_steps([updated_step | steps], remaining_lines, keywords)
        _ ->
          {Enum.reverse(all_steps), all_lines}
      end
    end
  end
end
