defmodule Gherkin.Elements.Step do
  @moduledoc """
  Represents an action to be executed as part of a scenario or background.
  """
  defstruct type: "",
            text: "",
            data_table: [],
            doc_string: "",
            line: 0,
            indent: 0

  def update(%__MODULE__{doc_string: ""} = step, :doc_string, doc_string) do
    %{step | doc_string: doc_string.doc_string}
  end

  def update(%__MODULE__{data_table: []} = step, :data_table, data_table) do
    %{step | data_table: data_table.data}
  end

  def finish(%__MODULE__{} = step) do
    step
  end
end
