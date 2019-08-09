defmodule Gherkin.ElementBuilder do
  alias Gherkin.Elements.{
    Background,
    DataTable,
    DocString,
    Examples,
    Feature,
    Rule,
    Scenario,
    ScenarioOutline,
    Step
  }

  @step_types [:and, :but, :given, :when, :then]
  def build(type, text, line, indent, []) when type in @step_types do
    {:ok, :step, %Step{type: type, text: text, line: line, indent: indent}}
  end

  def build(:feature, text, line, indent, tags) do
    {:ok, :feature, %Feature{text: text, line: line, indent: indent, tags: tags}}
  end

  def build(:scenario, text, line, indent, []) do
    {:ok, :scenario, %Scenario{text: text, line: line, indent: indent}}
  end

  def build(:scenario_outline, text, line, indent, []) do
    {:ok, :scenario_outline, %ScenarioOutline{text: text, line: line, indent: indent}}
  end

  def build(:background, text, line, indent, []) do
    {:ok, :background, %Background{text: text, line: line, indent: indent}}
  end

  def build(:examples, headers, line, indent, []) do
    {:ok, :examples, %Examples{headers: headers, line: line, indent: indent}}
  end

  def build(:rule, text, line, indent, []) do
    {:ok, :rule, %Rule{text: text, line: line, indent: indent}}
  end

  def build(:doc_string_open, type, line, indent, []) do
    {:ok, :doc_string, %DocString{type: type, line: line, indent: indent}}
  end

  def build(:data_table_open, headers, line, indent, []) do
    headers = Enum.map(headers, &String.to_atom/1)
    {:ok, :data_table, %DataTable{headers: headers, line: line, indent: indent}}
  end
end
