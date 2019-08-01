defmodule Gherkin.Elements.Rule do
  @moduledoc """
  Represents a single rule within a feature. Contains scenarios which demonstrate the rule.
  """
  defstruct name: "",
            description: "",
            background_steps: [],
            scenarios: [],
            line: 0,
            tags: []
end
