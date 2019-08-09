defmodule Gherkin.Elements.Scenario do
  @moduledoc """
  Represents a single scenario within a feature. Contains steps which are the primary focus of the scenario.
  """
  defstruct text: "",
            description: "",
            tags: [],
            steps: [],
            line: 0,
            indent: 0

  def update(%__MODULE__{steps: steps} = scenario, :step, step) do
    %{scenario | steps: [step | steps]}
  end

  def finish(%__MODULE__{steps: steps} = scenario) do
    %{scenario | steps: Enum.reverse(steps)}
  end
end
