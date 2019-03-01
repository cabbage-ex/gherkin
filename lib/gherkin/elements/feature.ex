defmodule Gherkin.Elements.Feature do
  @moduledoc """
  Representation of an entire feature. Contains rules and/or scenarios which are the primary focus of the feature.
  """
  defstruct name: "",
            description: "",
            tags: [],
            background_steps: [],
            rules: [],
            scenarios: [],
            line: 0,
            file: nil
end
