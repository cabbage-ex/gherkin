defmodule Gherkin.Parser do
  @moduledoc false
  alias File.Stream, as: FileStream
  alias Gherkin.ElementBuilder
  alias Gherkin.Parser.LineTypeDetector

  defstruct stack: [], incomplete: %{}, feature: nil, language: "", tags: []

  @ignore_types [:empty_line, :comment]
  @append_types [:description, :doc_string, :doc_string_close, :data_table]
  @doc """
  Parses a string that represents a Gherkin feature document into Elixir terms.
  """
  def parse(string, file_name \\ nil)

  def parse(string, file_name) when is_binary(string) do
    string
    |> String.split(~r/\r?\n/)
    |> parse_stream(file_name)
  end

  def parse(%FileStream{line_or_bytes: :line, path: path} = file_stream, file_name) do
    parse_stream(file_stream, path || file_name)
  end

  defp parse_stream(stream, file_name) do
    state = %__MODULE__{language: LineTypeDetector.default_language()}

    stream
    |> Stream.drop_while(&line_is_empty?/1)
    |> Stream.map(&indentify_line/1)
    |> Stream.with_index(1)
    |> Enum.reduce_while(state, &parse_each_line/2)
    |> finish_incomplete_elements(:all)
    |> elem(1)
    |> Map.get(:feature)
    |> Map.put(:file, file_name)
  end

  defp line_is_empty?(text) when is_binary(text), do: text === ""

  defp indentify_line(line) do
    text_without_indent = String.trim_leading(line)
    indent_size = String.length(line) - String.length(text_without_indent)
    {String.trim_trailing(text_without_indent), indent_size}
  end

  defp parse_each_line({{text, indent}, line}, %__MODULE__{} = acc) do
    case detect_type({text, indent}, acc) do
      {:ok, type, _text} when type in @ignore_types ->
        {:ok, acc}

      {:ok, type, text} when type in @append_types ->
        update_incomplete_element(acc, type, text)

      {:ok, :tags, tags} ->
        update_tags(acc, tags)

      {:ok, type, text} ->
        {:ok, type, element} = ElementBuilder.build(type, text, line, indent, acc.tags)
        start_incomplete_element(%{acc | tags: []}, type, element)
    end
    |> case do
      {:ok, acc} -> {:cont, acc}
      {:error, reason} -> {:halt, {:error, reason, line}}
    end
  end

  defp detect_type({text, indent}, acc) do
    case LineTypeDetector.detect_translatable_type(text, acc.language) do
      {:ok, type, text} ->
        {:ok, type, text}

      {:error, :no_match} ->
        LineTypeDetector.detect_constant_type({text, indent}, List.first(acc.stack))
    end
  end

  defp start_incomplete_element(%__MODULE__{} = acc, type, element) do
    {:ok, acc} = finish_incomplete_elements(acc, {type, element.indent})

    stack = [{type, element.indent} | acc.stack]
    incomplete = Map.put(acc.incomplete, type, element)

    {:ok, %{acc | stack: stack, incomplete: incomplete}}
  end

  defp finish_incomplete_elements(%__MODULE__{} = acc, :all) do
    finish_incomplete_elements(acc, {:feature, 0})
  end

  defp finish_incomplete_elements(%__MODULE__{} = acc, {finish_type, finish_indent}) do
    if should_finish_top_stack_item?(acc.stack, {finish_type, finish_indent}) do
      [{finish_stack_type, _finish_stack_indent} | remaining_stack] = acc.stack
      {finish_element, remaining_elements} = Map.pop(acc.incomplete, finish_stack_type)

      {:ok, acc} =
        update_incomplete_element(
          %{acc | stack: remaining_stack, incomplete: remaining_elements},
          finish_stack_type,
          apply(finish_element.__struct__, :finish, [finish_element])
        )

      finish_incomplete_elements(acc, {finish_type, finish_indent})
    else
      {:ok, acc}
    end
  end

  defp update_incomplete_element(%__MODULE__{} = acc, :feature, feature) do
    {:ok, %{acc | feature: feature}}
  end

  defp update_incomplete_element(%__MODULE__{} = acc, type, extra_value) do
    path = [Access.key(:incomplete), acc.stack |> List.first() |> elem(0)]
    acc = update_in(acc, path, &update_incomplete_element(&1, type, extra_value))
    {:ok, acc}
  end

  defp update_incomplete_element(%_{} = element, type, extra_value) do
    apply(element.__struct__, :update, [element, type, extra_value])
  end

  defp update_tags(%__MODULE__{tags: tags} = acc, new_tags) do
    {:ok, %{acc | tags: Enum.concat(tags, new_tags)}}
  end

  defp should_finish_top_stack_item?(stack, {type, indent}) do
    case {List.first(stack), {type, indent}} do
      {nil, {_type, _indent}} -> false
      {{type, _}, {type, _}} -> true
      {{stack_type, _}, {_, _}} when stack_type in [:data_table, :doc_string] -> true
      {{_, indent}, {type, indent}} when type in [:data_table, :doc_string] -> false
      {{_, stack_indent}, {_, indent}} when indent <= stack_indent -> true
      _ -> false
    end
  end
end
