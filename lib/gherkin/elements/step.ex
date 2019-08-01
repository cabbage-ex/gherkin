defmodule Gherkin.Elements.Step do
  @moduledoc """
  Represents an action to be executed as part of a scenario or background.
  """
  defstruct(keyword: "", text: "", table_data: [], doc_string: "", line: 0)
end
