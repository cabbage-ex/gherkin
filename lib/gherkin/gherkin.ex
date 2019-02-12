defmodule Gherkin do
  @moduledoc """
  See `Gherkin.parse/1` for primary usage.
  """

  @doc """
  Primary helper function for parsing files or streams through `Gherkin`. To use
  simply call this function passing in the full text of the file or a file stream.

  Example:

      %Gherkin.Elements.Feature{scenarios: scenarios} = File.read!("test/features/coffee.feature") |> Gherkin.parse()
      # Do something with `scenarios`

      # Also supports file streams for larger files (must read by lines, bytes not supported)
      %Gherkin.Elements.Feature{scenarios: scenarios} = File.stream!("test/features/coffee.feature") |> Gherkin.parse()
  """
  def parse(string_or_stream) do
    Gherkin.Parser.parse_feature(string_or_stream)
  end

  def parse_file(file_name) do
    file_name
    |> File.read!()
    |> Gherkin.Parser.parse_feature(file_name)
  end

  @doc """
  Changes a `Gherkin.Elements.ScenarioOutline` into multiple `Gherkin.Elements.Scenario`s
  so that they may be executed in the same manner.

  Given an outline, its easy to run all scenarios:

      outline = %Gherkin.Elements.ScenarioOutline{}
      Gherkin.scenarios_for(outline) |> Enum.each(&run_scenario/1)
  """
  def scenarios_for(%Gherkin.Elements.ScenarioOutline{
        name: name,
        tags: tags,
        steps: steps,
        examples: examples,
        line: line
      } = scenario) do
    examples
    |> Enum.with_index(1)
    |> Enum.map(fn {example, index} ->
      %Gherkin.Elements.Scenario{
        name: name <> " (Example #{index})",
        tags: tags,
        line: line,
        steps:
          Enum.map(steps, fn step ->
            %{
              step
              | text:
                  Enum.reduce(example, step.text, fn {k, v}, t ->
                    String.replace(t, ~r/<#{k}>/, v)
                  end)
            }
          end)
      }
    end)
  end

  @doc """
  Given a `Gherkin.Element.Feature`, changes all `Gherkin.Elements.ScenarioOutline`s
  into `Gherkin.ElementScenario` as a flattened list of scenarios.
  """
  def flatten(feature = %Gherkin.Elements.Feature{scenarios: scenarios}) do
    %{
      feature
      | scenarios:
          scenarios
          |> Enum.map(fn
            # Nothing to do
            scenario = %Gherkin.Elements.Scenario{} -> scenario
            outline = %Gherkin.Elements.ScenarioOutline{} -> scenarios_for(outline)
          end)
          |> List.flatten()
    }
  end
end
