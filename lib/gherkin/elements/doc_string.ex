defmodule Gherkin.Elements.DocString do
  defstruct type: "",
            doc_string: [],
            is_closed?: false,
            line: 0,
            indent: 0

  def update(%__MODULE__{doc_string: doc_string} = doc, :doc_string, new_line) do
    %{doc | doc_string: [new_line | doc_string]}
  end

  def update(%__MODULE__{} = doc, :doc_string_close, _) do
    %{doc | is_closed?: true}
  end

  def finish(%__MODULE__{doc_string: doc_string, is_closed?: true} = doc) do
    doc_string = doc_string |> Enum.reverse() |> Enum.join("\n") |> String.trim()
    %{doc | doc_string: doc_string}
  end
end
