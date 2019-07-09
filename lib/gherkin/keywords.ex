defmodule Gherkin.Keywords do
  alias __MODULE__

  @keywords_file_path Path.expand("../../gherkin-languages.json", __DIR__)

  defstruct and: [],
            background: [],
            but: [],
            examples: [],
            feature: [],
            given: [],
            name: "",
            native: "",
            rule: [],
            scenario: [],
            scenario_outline: [],
            then: [],
            when: []

  @doc """
    Get keywords from loaded keywords for given language

    Returns a Keywords struct with atom keys
  """
  def get_keywords(language \\ "en") do
    keywords_map = language
                   |> load_language_keywords()
                   |> atomize_map()

    struct!(Keywords, keywords_map)
  end

  @doc """
    Transform a given keyword struct into a list of keywords
    And optionally filter it with given keys list

    Returns a list of keyword strings
  """
  def get_keywords_list(%Keywords{} = keywords, keys_list \\ nil) do
    list = keywords
           |> setup_list()
           |> Enum.filter(fn ({_, keyword}) -> is_list(keyword) end)
    filtered_list = if keys_list, do: Enum.filter(list, fn ({key, _}) -> Enum.member?(keys_list, key) end), else: list
    cleanup_list(filtered_list)
  end

  def get_step_keywords_list(keywords) do
    get_keywords_list(keywords, [:given, :when, :then, :and, :but])
  end

  def get_description_keywords_list(keywords) do
    get_keywords_list(keywords, [:background, :feature, :examples, :scenario, :given, :rule, :then, :and, :but])
  end

  @doc """
    Find a matched keyword from given keywords list inside given text

    Returns a keyword string
  """
  def find_keyword_from_list(text, keywords) do
    Enum.find(
      keywords,
      fn keyword ->
        String.match?(text, ~r/^\b(#{keyword})(\b|:)/)
      end
    )
  end

  @doc """
    Check if given text contains on of the given keywords

    Returns a boolean
  """
  def match_keywords?(text, keywords) do
    Enum.any?(
      keywords,
      fn keyword ->
        String.match?(text, ~r/^\b(#{keyword})(\b|:)/)
      end
    )
  end

  defp setup_list(%Keywords{} = keywords) do
    # Transform a Keywords struct into a map and filter keywords keys which aren't lists (eg. name or native)
    keywords
    |> Map.from_struct()
    |> Enum.filter(fn ({_, keyword}) -> is_list(keyword) end)
  end

  defp cleanup_list(list) do
    list
    |> Enum.map(fn ({_, value}) -> value end)
    |> List.flatten()
    |> Enum.filter(fn value -> value != "* " end)
    |> Enum.map(fn value -> String.trim(value)  end)
  end

  defp load_language_keywords(language) do
    case get_json(@keywords_file_path) do
      %{^language => json_keywords} -> json_keywords
      _ -> raise("Language \"#{language}\" is not included in gherkin-language.")
    end
  end

  defp get_json(filename) do
    with {:ok, body} <- File.read(filename),
         {:ok, json} <- Jason.decode(body), do: json
  end

  defp atomize_map(map) do
    for {key, val} <- map,
        into: %{},
        do: {
          key
          |> Macro.underscore()
          |> String.to_atom(),
          val
        }
  end
end
