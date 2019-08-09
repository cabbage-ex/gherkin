defmodule Gherkin.Parser.LineTypeDetector do
  @moduledoc """
  Detects .feature files keywords such as `Feature`, `Scenario` and steps like `Given`, `Then` and so on.
  """
  @keywords_file_path Application.fetch_env!(:gherkin, :file_path)
  @json_parser_function Application.fetch_env!(:gherkin, :json_parser_function)
  @selected_language Application.fetch_env!(:gherkin, :language)

  @types [
    "and",
    "but",
    "given",
    "when",
    "then",
    "background",
    "examples",
    "feature",
    "rule",
    "scenario",
    "scenarioOutline"
  ]

  @language_prefix "# language:"
  @comment_prefix "#"
  @docstring_prefix "\"\"\""
  @datatable_prefix "|"
  @tag_prefix "@"

  @keywords @keywords_file_path
            |> File.read!()
            |> @json_parser_function.()
            |> Enum.into(%{}, fn {langauge, keywords} ->
              prepared_keywords =
                Enum.flat_map(@types, fn key ->
                  keywords
                  |> Map.get(key, [])
                  |> Enum.map(fn keyword ->
                    type_key = key |> Macro.underscore() |> String.to_atom()

                    type_value =
                      if String.ends_with?(keyword, " "),
                        do: String.trim_trailing(keyword),
                        else: keyword <> ":"

                    {type_key, type_value}
                  end)
                end)

              {langauge, prepared_keywords}
            end)

  def default_language, do: @selected_language

  def detect_translatable_type(text, language) do
    with {:lang, keywords} when not is_nil(keywords) <- {:lang, Map.get(@keywords, language)},
         {:keyword, {type, prefix}} <- {:keyword, Enum.find(keywords, &starts_with?(text, &1))},
         prepared_text <- subtract_prefix(text, prefix) do
      {:ok, type, prepared_text}
    else
      {:lang, nil} -> {:error, :unsupported_language_selected}
      {:keyword, nil} -> {:error, :no_match}
    end
  end

  def detect_constant_type({text, line_indent}, {:doc_string, doc_indent}) do
    cond do
      starts_with?(text, @docstring_prefix) ->
        {:ok, :doc_string_close, ""}

      true ->
        prepared_text =
          case line_indent - doc_indent do
            0 -> text
            diff when diff > 0 -> String.pad_leading(text, diff + String.length(text))
            diff when diff < 0 -> throw(:wtf_indent_goes_backwards?)
          end

        {:ok, :doc_string, prepared_text}
    end
  end

  def detect_constant_type({text, line_indent}, {:data_table, data_indent}) do
    if starts_with?(text, @datatable_prefix) do
      prepared_text =
        case line_indent - data_indent do
          0 -> parse_data_table_line(text)
          _ -> throw(:wtf_different_indent?)
        end

      {:ok, :data_table, prepared_text}
    else
      detect_constant_type({text, line_indent}, {nil, nil})
    end
  end

  def detect_constant_type({text, _line_indent}, _) do
    cond do
      text === "" ->
        {:ok, :empty_line, ""}

      starts_with?(text, @language_prefix) ->
        {:ok, :language, subtract_prefix(text, @language_prefix)}

      starts_with?(text, @comment_prefix) ->
        {:ok, :comment, subtract_prefix(text, @comment_prefix)}

      starts_with?(text, @docstring_prefix) ->
        {:ok, :doc_string_open, subtract_prefix(text, @docstring_prefix)}

      starts_with?(text, @datatable_prefix) ->
        {:ok, :data_table_open, parse_data_table_line(text)}

      starts_with?(text, @tag_prefix) ->
        {:ok, :tags, parse_tag_line(text)}

      true ->
        {:ok, :description, String.trim(text)}
    end
  end

  defp starts_with?(text, {_type, prefix}), do: String.starts_with?(text, prefix)
  defp starts_with?(text, prefix), do: String.starts_with?(text, prefix)

  defp subtract_prefix(text, prefix), do: text |> String.trim_leading(prefix) |> String.trim()

  defp parse_data_table_line(text) do
    text
    |> String.trim(@datatable_prefix)
    |> String.split(@datatable_prefix)
    |> Enum.map(&String.trim/1)
  end

  defp parse_tag_line(text) do
    text
    |> String.trim(@tag_prefix)
    |> String.split(@tag_prefix)
    |> Enum.map(fn item ->
      item
      |> String.trim()
      |> String.split(" ")
      |> case do
        [tag] -> String.to_atom(tag)
        [tag, value] -> {String.to_atom(tag), parse_tag_value(value)}
      end
    end)
  end

  defp parse_tag_value(value) do
    case Float.parse(value) do
      {value, ""} ->
        if Float.floor(value) == value, do: round(value), else: value

      :error ->
        value
    end
  end
end
