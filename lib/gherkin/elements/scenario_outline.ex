defmodule Gherkin.Elements.ScenarioOutline do
  @moduledoc """
  Represents an outline of a single scenario.
  """
  defstruct text: "",
            description: "",
            tags: [],
            steps: [],
            examples: [],
            line: 0,
            indent: 0

  def update(%__MODULE__{steps: steps} = scenario_outline, :step, step) do
    %{scenario_outline | steps: [step | steps]}
  end

  def update(%__MODULE__{examples: []} = scenario_outline, :examples, examples) do
    %{scenario_outline | examples: examples.data_table}
  end

  def finish(%__MODULE__{steps: steps} = scenario_outline) do
    %{scenario_outline | steps: Enum.reverse(steps)}
  end
end
