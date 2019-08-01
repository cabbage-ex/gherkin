defmodule Gherkin.Elements.Scenario do
  @moduledoc """
  Represents a single scenario within a feature. Contains steps which are the primary focus of the scenario.
  """
  defstruct name: "",
            description: "",
            tags: [],
            steps: [],
            line: 0
end
