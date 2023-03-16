defmodule Gherkin.Parsers.TableParser do
  @moduledoc false

  @column_separator ~r/(?<!\\)\|/

  def parse_table(header_line, table_lines) do
    keys = table_line_to_columns(header_line) |> Enum.map(&String.to_atom/1)
    parse_table_lines(keys, table_lines)
  end

  defp parse_table_lines(keys, lines, kv_pairs \\ [])
  defp parse_table_lines(_keys, [], kv_pairs), do: {Enum.reverse(kv_pairs), []}

  defp parse_table_lines(keys, [line | lines] = all_lines, kv_pairs) do
    case line do
      %{text: "|" <> text} = _ ->
        new_row = Enum.zip(keys, table_line_to_columns(text)) |> Enum.into(Map.new())
        parse_table_lines(keys, lines, [new_row | kv_pairs])

      _ ->
        {Enum.reverse(kv_pairs), all_lines}
    end
  end

  defp table_line_to_columns(line) do
    line
    |> String.split(@column_separator, trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.map(&unescape_pipes/1)
  end

  defp unescape_pipes(cell), do: String.replace(cell, ~S(\|), "|")
end
