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

  defmodule Elements do
    @moduledoc false
    defmodule Feature do
      @moduledoc """
      Representation of an entire feature. Contains scenarios which are the primary focus of the feature.
      """
      defstruct name: "",
                description: "",
                tags: [],
                role: nil,
                background_steps: [],
                scenarios: [],
                line: 0,
                file: nil
    end

    defmodule Scenario do
      @moduledoc """
      Represents a single scenario within a feature. Contains steps which are the primary focus of the scenario.
      """
      defstruct name: "",
                tags: [],
                steps: [],
                line: 0
    end

    defmodule ScenarioOutline do
      @moduledoc """
      Represents an outline of a single scenario.
      """
      defstruct name: "",
                tags: [],
                steps: [],
                examples: [],
                line: 0
    end

    defmodule Steps do
      @moduledoc false
      defmodule Given, do: defstruct text: "", table_data: [], doc_string: "", line: 0
      defmodule When,  do: defstruct text: "", table_data: [], doc_string: "", line: 0
      defmodule Then,  do: defstruct text: "", table_data: [], doc_string: "", line: 0
      defmodule And,   do: defstruct text: "", table_data: [], doc_string: "", line: 0
      defmodule But,   do: defstruct text: "", table_data: [], doc_string: "", line: 0
    end

  end

  @doc """
  Changes a `Gherkin.Elements.ScenarioOutline` into multiple `Gherkin.Elements.Scenario`s
  so that they may be executed in the same manner.

  Given an outline, its easy to run all scenarios:

      outline = %Gherkin.Elements.ScenarioOutline{}
      Gherkin.scenarios_for(outline) |> Enum.each(&run_scenario/1)
  """
  def scenarios_for(%Elements.ScenarioOutline{name: name, tags: tags, steps: steps, examples: examples, line: line}) do
    examples
    |> Enum.with_index()
    |> Enum.map(fn({example, index}) ->
      %Elements.Scenario{
        name: name <> " (Example #{index + 1})",
        tags: tags,
        line: line,
        steps: Enum.map(steps, fn(step)->
          %{step | text: Enum.reduce(example, step.text, fn({k,v}, t)->
            String.replace(t, ~r/<#{k}>/, v)
          end)}
        end)
      }
    end)
  end

  @doc """
  Given a `Gherkin.Element.Feature`, changes all `Gherkin.Elements.ScenarioOutline`s
  into `Gherkin.ElementScenario` as a flattened list of scenarios.
  """
  def flatten(feature = %Gherkin.Elements.Feature{scenarios: scenarios}) do
    %{feature | scenarios: scenarios |> Enum.map(fn
      scenario = %Gherkin.Elements.Scenario{} -> scenario # Nothing to do
      outline = %Gherkin.Elements.ScenarioOutline{} -> scenarios_for(outline)
    end) |> List.flatten()}
  end

end
