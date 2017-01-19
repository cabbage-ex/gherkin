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
                scenarios: []
    end

    defmodule Scenario do
      @moduledoc """
      Represents a single scenario within a feature. Contains steps which are the primary focus of the scenario.
      """
      defstruct name: "",
                tags: [],
                steps: []
    end

    defmodule ScenarioOutline do
      @moduledoc """
      Represents an outline of a single scenario.
      """
      defstruct name: "",
                tags: [],
                steps: [],
                examples: []
    end

    defmodule Steps do
      @moduledoc false
      defmodule Given, do: defstruct text: "", table_data: [], doc_string: ""
      defmodule When,  do: defstruct text: "", table_data: [], doc_string: ""
      defmodule Then,  do: defstruct text: "", table_data: [], doc_string: ""
      defmodule And,   do: defstruct text: "", table_data: [], doc_string: ""
      defmodule But,   do: defstruct text: "", table_data: [], doc_string: ""
    end

  end

end
