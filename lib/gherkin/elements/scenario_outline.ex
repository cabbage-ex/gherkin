defmodule Gherkin.Elements.ScenarioOutline do
  @moduledoc """
  Represents an outline of a single scenario.
  """
  defstruct name: "",
            description: "",
            tags: [],
            steps: [],
            examples: [],
            line: 0
end
