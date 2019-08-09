defmodule Gherkin.Elements.DataTable do
  defstruct headers: "",
            data: [],
            line: 0,
            indent: 0

  def update(%__MODULE__{headers: headers, data: data} = data_table, :data_table, new_line) do
    new_line = [headers, new_line] |> List.zip() |> Map.new()

    %{data_table | data: [new_line | data]}
  end

  # def update(%__MODULE__{} = doc, :doc_string_close, _) do
  #   %{doc | is_closed?: true}
  # end

  def finish(%__MODULE__{data: data} = data_table) do
    %{data_table | data: Enum.reverse(data)}
  end
end
