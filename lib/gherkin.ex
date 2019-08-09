defmodule Gherkin do
  @moduledoc """
  See `Gherkin.parse/1` for primary usage.
  """

  alias Gherkin.Parser

  @doc """
  Primary helper function for parsing binary or streams through `Gherkin`. To use
  simply call this function passing in the full text of the file or a file stream.

  Example:

    iex> "test/fixtures/coffee.feature" |> File.read!() |> Gherkin.parse()
    %Gherkin.Elements.Feature{
      description: "As a Barrista
    Coffee should not be served until paid for
    Coffee should not be served until the button has been pressed
    If there is no coffee left then money should be refunded",
      line: 1,
      indent: 0,
      text: "Serve coffee",
      scenarios: [
        %Gherkin.Elements.Scenario{
          indent: 2,
          line: 7,
          text: "Buy last coffee",
          steps: [
            %Gherkin.Elements.Step{
              indent: 4,
              type: :given,
              line: 8,
              text: "there are 1 coffees left in the machine"
            }
          ],
        }
      ],
    }

    # Also supports file streams for larger files (must read by lines, bytes not supported)
    iex> "test/fixtures/coffee.feature" |> File.stream!() |> Gherkin.parse()
    %Gherkin.Elements.Feature{
      description: "As a Barrista
    Coffee should not be served until paid for
    Coffee should not be served until the button has been pressed
    If there is no coffee left then money should be refunded",
      line: 1,
      file: "test/fixtures/coffee.feature",
      indent: 0,
      text: "Serve coffee",
      scenarios: [
        %Gherkin.Elements.Scenario{
          line: 7,
          indent: 2,
          text: "Buy last coffee",
          steps: [
            %Gherkin.Elements.Step{
              type: :given,
              line: 8,
              indent: 4,
              text: "there are 1 coffees left in the machine"
            }
          ],
        }
      ],
    }
  """
  def parse(string_or_stream, file_name \\ nil) do
    Parser.parse(string_or_stream, file_name)
  end

  @doc """
  Primary helper function for parsing file through `Gherkin`. To use
  simply call this function passing in the relative path to file.

  Example:

    iex> Gherkin.parse_file("test/fixtures/coffee.feature")
    %Gherkin.Elements.Feature{
      description: "As a Barrista
    Coffee should not be served until paid for
    Coffee should not be served until the button has been pressed
    If there is no coffee left then money should be refunded",
      file: "test/fixtures/coffee.feature",
      line: 1,
      indent: 0,
      text: "Serve coffee",
      scenarios: [
        %Gherkin.Elements.Scenario{
          line: 7,
          indent: 2,
          text: "Buy last coffee",
          steps: [
            %Gherkin.Elements.Step{
              type: :given,
              line: 8,
              indent: 4,
              text: "there are 1 coffees left in the machine"
            }
          ],
        }
      ],
    }
  """
  def parse_file(file_name) do
    file_name
    |> File.read!()
    |> Parser.parse(file_name)
  end

  # @doc """
  # Given a `Gherkin.Element.Feature`, changes all `Gherkin.Elements.ScenarioOutline`s
  # into `Gherkin.ElementScenario` as a flattened list of scenarios.
  # """
  # def flatten(feature = %Feature{scenarios: scenarios}) do
  #   %{
  #     feature
  #     | scenarios:
  #         scenarios
  #         |> Enum.map(fn
  #           # Nothing to do
  #           scenario = %Scenario{} -> scenario
  #           outline = %ScenarioOutline{} -> scenarios_for(outline)
  #         end)
  #         |> List.flatten()
  #   }
  # end

  # @doc """
  # Changes a `Gherkin.Elements.ScenarioOutline` into multiple `Gherkin.Elements.Scenario`s
  # so that they may be executed in the same manner.

  # Given an outline, its easy to run all scenarios:

  #     outline = %Gherkin.Elements.ScenarioOutline{}
  #     Gherkin.scenarios_for(outline) |> Enum.each(&run_scenario/1)
  # """
  # def scenarios_for(%ScenarioOutline{
  #       text: name,
  #       tags: tags,
  #       steps: steps,
  #       examples: examples,
  #       line: line
  #     }) do
  #   examples
  #   |> Enum.with_index(1)
  #   |> Enum.map(fn {example, index} ->
  #     %Scenario{
  #       name: name <> " (Example #{index})",
  #       tags: tags,
  #       line: line,
  #       steps:
  #         Enum.map(steps, fn step ->
  #           %{
  #             step
  #             | text:
  #                 Enum.reduce(example, step.text, fn {k, v}, t ->
  #                   String.replace(t, ~r/<#{k}>/, v)
  #                 end)
  #           }
  #         end)
  #     }
  #   end)
  # end
end
