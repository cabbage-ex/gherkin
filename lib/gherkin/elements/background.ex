defmodule Gherkin.Elements.Background do
  @moduledoc """
  Representation of an entire feature. Contains rules and/or scenarios which are the primary focus of the feature.
  """
  defstruct text: "",
            description: "",
            tags: [],
            steps: [],
            line: 0,
            indent: 0

  def update(%__MODULE__{steps: steps} = acc, :step, step) do
    %{acc | steps: [step | steps]}
  end

  def finish(%__MODULE__{steps: steps} = background) do
    %{background | steps: Enum.reverse(steps)}
  end
end
