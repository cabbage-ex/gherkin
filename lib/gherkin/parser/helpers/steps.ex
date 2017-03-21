defmodule Gherkin.Parser.Helpers.Steps do
  @moduledoc false
  alias Gherkin.Elements.Steps, as: Steps

  def process_background_step_line(line, feature, line_number) do
    %{background_steps: current_background_steps} = feature
    new_step = string_to_step(line, line_number)
    {
      %{feature | background_steps: current_background_steps ++ [new_step]},
      :background_steps
    }
  end

  def process_scenario_step_line(line, feature, line_number) do
    %{scenarios: [scenario | rest]} = feature
    updated_scenario = add_step_to_scenario(scenario, line, line_number)
    {
      %{feature | scenarios: [updated_scenario | rest]},
      {:scenario_steps, []} # Empty keys state for tables
    }
  end

  @doc ~S"""
  Takes a string representing a step and adds it to the scenario as a struct

  ## Examples

  iex> add_step_to_scenario(%{steps: []}, "When I add this line", 10)
  %{steps: [%Steps.When{text: "I add this line", line: 10}]}

  """
  def add_step_to_scenario(scenario, line, line_number) do
    step  = string_to_step(line, line_number)
    %{steps: current_steps} = scenario
    %{scenario | steps: current_steps ++ [step]}
  end

  @doc ~S"""
  Returns the appropriate struct for a step string

  ## Examples

  iex> string_to_step("Given this works", 5)
  %Steps.Given{text: "this works", line: 5}

  iex> string_to_step("Then it might be useful", 8)
  %Steps.Then{text: "it might be useful", line: 8}

  """
  def string_to_step(string, line) do
    case string do
      "Given " <> text -> %Steps.Given{text: text, line: line}
      "When " <> text  -> %Steps.When{text: text, line: line}
      "Then " <> text  -> %Steps.Then{text: text, line: line}
      "And " <> text  -> %Steps.And{text: text, line: line}
      "But " <> text  -> %Steps.But{text: text, line: line}
    end
  end

end
