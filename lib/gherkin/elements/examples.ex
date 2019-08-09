defmodule Gherkin.Elements.Examples do
  defstruct headers: [],
            data_table: [],
            line: 0,
            indent: 0

  def update(%__MODULE__{data_table: []} = examples, :data_table, data_table) do
    %{examples | data_table: data_table.data}
  end

  def finish(%__MODULE__{} = examples) do
    examples
  end
end
