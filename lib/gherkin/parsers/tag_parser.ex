defmodule Gherkin.Parsers.TagParser do
  @moduledoc false

  def process_tags(lines) do
    {tag_lines, remaining_lines} =
      Enum.split_while(lines, fn
        %{text: "@" <> _} = _ -> true
        _ -> false
      end)

    {Enum.flat_map(tag_lines, &extract_tags/1), remaining_lines}
  end

  defp extract_tags(line) do
    line.text
    |> String.split("@", trim: true)
    |> Enum.map(&extract_tag/1)
  end

  defp extract_tag(tag) do
    case tag |> String.trim() |> String.split(" ") do
      [t] ->
        String.to_atom(t)

      [t, v] ->
        case Float.parse(v) do
          {num, ""} ->
            # Convert from float to int if it is exactly
            num = if Float.floor(num) == num, do: round(num), else: num
            {String.to_atom(t), num}

          :error ->
            {String.to_atom(t), v}
        end
    end
  end
end
