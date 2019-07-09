defmodule Gherkin.Elements.Line do
  @moduledoc false

  defstruct raw_text: "", text: "", line_number: nil

  def get_line_name(line_text) do
    [_, line_name] = String.split(line_text, ":", parts: 2)
    line_name
  end
end
