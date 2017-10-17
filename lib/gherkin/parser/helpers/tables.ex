defmodule Gherkin.Parser.Helpers.Tables do
  @moduledoc false
  def process_step_table_line(line, feature, keys) do
    %{scenarios: [scenario | rest]} = feature
    {updated_scenario, keys} = scenario |> add_table_row_to_last_step(line, keys)
    {
      %{feature | scenarios: [updated_scenario | rest]},
      {:scenario_steps, keys}
    }
  end

  def process_outline_table_line(line, feature, keys) do
    %{scenarios: [scenario_outline | rest]} = feature
    {updated_scenario_outline, keys} = scenario_outline
                                       |> add_table_row_to_example(line, keys)
    {
      %{feature | scenarios: [updated_scenario_outline | rest]},
      {:scenario_outline_example, keys}
    }
  end

  defp add_table_row_to_last_step(scenario, line, []) do
    {scenario, table_line_to_columns(line) |> Enum.map(&String.to_atom/1)}
  end
  defp add_table_row_to_last_step(scenario, line, keys) do
    new_row = Enum.zip(keys, table_line_to_columns(line)) |> Enum.into(Map.new)
    %{steps: current_steps} = scenario
    [%{table_data: current_rows} = last_step | other_steps] = current_steps
      |> Enum.reverse

    updated_step = %{last_step | table_data: current_rows ++ [new_row]}
    updated_steps = [updated_step | other_steps] |> Enum.reverse

    {%{scenario | steps: updated_steps}, keys}
  end

  defp add_table_row_to_example(scenario_outline, line, []) do
    {scenario_outline, table_line_to_columns(line) |> Enum.map(&String.to_atom/1)}
  end
  defp add_table_row_to_example(scenario_outline, line, keys) do
    new_row = Enum.zip(keys, table_line_to_columns(line)) |> Enum.into(Map.new)
    update_examples = scenario_outline.examples ++ [new_row]
    {%{scenario_outline | examples: update_examples}, keys}
  end

  defp table_line_to_columns(line) do
    line
    |> String.split("|", trim: true)
    |> Enum.map(&String.trim/1)
  end

end
