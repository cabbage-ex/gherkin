defmodule Gherkin.Parsers.DocStringParser do
  @moduledoc false

  def parse_doc_string(step, []), do: {step, []}

  def parse_doc_string(step, [line | lines]) do
    case line.text do
      ~s(""") <> _ ->
        {step, lines}

      _ ->
        parse_doc_string(%{step | doc_string: step.doc_string <> line.text <> "\n"}, lines)
    end
  end
end
