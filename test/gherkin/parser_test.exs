defmodule Gherkin.ParserTest do
  use ExUnit.Case
  import Gherkin.Parser
  alias Gherkin.Elements.Steps, as: Steps
  alias Gherkin.Elements.Feature

  @feature_text """
    Feature: Serve coffee
      Coffee should not be served until paid for
      Coffee should not be served until the button has been pressed
      If there is no coffee left then money should be refunded

      Scenario: Buy last coffee
        Given there are 1 coffees left in the machine
        And I have deposited 1$
        When I press the coffee button
        Then I should be served a coffee

      Scenario: Be sad that no coffee is left
        Given there are 0 coffees left in the machine
        And I have deposited 1$
        When I press the coffee button
        Then I should be frustrated
  """

  @feature_with_backgroundtext """
  Feature: Serve coffee
    Coffee should not be served until paid for
    Coffee should not be served until the button has been pressed
    If there is no coffee left then money should be refunded

    Background:
      Given coffee exists as a beverage
      And there is a coffee machine

    Scenario: Buy last coffee
      Given there are 1 coffees left in the machine
      And I have deposited 1$
      When I press the coffee button
      Then I should be served a coffee
  """

  @feature_with_single_feature_tag """
  @beverage
  Feature: Serve coffee
    Coffee should not be served until paid for
    Coffee should not be served until the button has been pressed
    If there is no coffee left then money should be refunded

  Scenario: Buy last coffee
    Given there are 1 coffees left in the machine
  """

  @feature_with_value_feature_tag """
  @cost 1
  Feature: Serve coffee
    Coffee should not be served until paid for
    Coffee should not be served until the button has been pressed
    If there is no coffee left then money should be refunded

  Scenario: Buy last coffee
    Given there are 1 coffees left in the machine
  """

  @feature_with_multiple_feature_tag """
  @beverage @coffee
  @caffeine
  Feature: Serve coffee
    Coffee should not be served until paid for
    Coffee should not be served until the button has been pressed
    If there is no coffee left then money should be refunded

  Scenario: Buy last coffee
    Given there are 1 coffees left in the machine
  """

  @feature_with_step_with_table """
  Feature: Have tables
    Sometimes data is a table

    Scenario: I have a step with a table
      Given the following table
      | Column one | Column two |
      | Hello      | World      |
      Then everything should be okay
  """

  @feature_with_doc_string "
  Feature: Have tables
    Sometimes data is a table

    Scenario: I have a step with a doc string
      Given the following data
      \"\"\"json
      {
        \"a\": \"b\"
      }
      \"\"\"
      Then everything should be okay
  "

  @feature_with_scenario_outline """
  Feature: Scenario outlines exist

    Scenario Outline: eating
      Given there are <start> cucumbers
      When I eat <eat> cucumbers
      Then I should have <left> cucumbers

    Examples:
      | start | eat | left |
      |  12   |  5  |  7   |
      |  20   |  5  |  15  |
  """

  @feature__with_comments """
    Feature: Serve coffee
      Coffee should not be served until paid for
      Coffee should not be served until the button has been pressed
      If there is no coffee left then money should be refunded

      #Only one coffee? this is bad!
      Scenario: Buy last coffee
        Given there are 1 coffees left in the machine
        And I have deposited 1$
        When I press the coffee button
        # I better get some coffee
        Then I should be served a coffee
  """

  @feature_with_role """
  Feature: Serve coffee
    As a Barrista
    Coffee should not be served until paid for
    Coffee should not be served until the button has been pressed
    If there is no coffee left then money should be refunded

  Scenario: Buy last coffee
    Given there are 1 coffees left in the machine
  """

  @feature_with_scenario_with_no_name """
  Feature: Serve coffee
    Coffee should not be served until paid for
    Coffee should not be served until the button has been pressed
    If there is no coffee left then money should be refunded

    Scenario:
      Given there are 1 coffees left in the machine
  """

  test "Parses the feature name" do
    assert %Feature{name: name, line: 1} = parse_feature(@feature_text)
    assert name == "Serve coffee"
  end

  test "Parses the feature description" do
    assert %Feature{description: description, line: 1} = parse_feature(@feature_text)
    assert description == """
    Coffee should not be served until paid for
    Coffee should not be served until the button has been pressed
    If there is no coffee left then money should be refunded
    """
  end

  test "Parses the feature role from an 'As a XXXX' line" do
    assert %Feature{role: role, line: 1} = parse_feature(@feature_with_role)
    assert role == "Barrista"
  end

  test "reads in the correct number of scenarios" do
    assert %Feature{scenarios: scenarios, line: 1} = parse_feature(@feature_text)
    assert Enum.count(scenarios) == 2
  end

  test "Reads in scenarios with no name" do
    assert %Feature{scenarios: scenarios, line: 1} = parse_feature(@feature_with_scenario_with_no_name)
    assert Enum.count(scenarios) == 1
  end

  test "Gets the scenario's name" do
    assert %Feature{scenarios: [%{name: name} | _], line: 1} = parse_feature(@feature_text)
    assert name == "Buy last coffee"
  end

  test "Gets the correct number of steps for the scenario" do
    assert %Feature{scenarios: [%{steps: steps} | _], line: 1} = parse_feature(@feature_text)
    assert Enum.count(steps) == 4
  end

  test "Has the correct steps for a scenario" do
    expected_steps = [
      %Steps.Given{text: "there are 1 coffees left in the machine", line: 7},
      %Steps.And{text: "I have deposited 1$", line: 8},
      %Steps.When{text: "I press the coffee button", line: 9},
      %Steps.Then{text: "I should be served a coffee", line: 10}
    ]
    %{scenarios: [%{steps: steps} | _]} = parse_feature(@feature_text)
    assert expected_steps == steps
  end

  test "Parses the expected background steps" do
    expected_steps = [
      %Steps.Given{text: "coffee exists as a beverage", line: 7},
      %Steps.And{text: "there is a coffee machine", line: 8}
    ]
    %{background_steps: background_steps} = parse_feature(@feature_with_backgroundtext)
    assert expected_steps == background_steps
  end

  test "Reads a doc string in to the correct step" do
    expected_data = "{\n  \"a\": \"b\"\n}\n"
    expected_steps = [
      %Steps.Given{text: "the following data", doc_string: expected_data, line: 6},
      %Steps.Then{text: "everything should be okay", line: 12},
    ]
    %{scenarios: [%{steps: steps} | _]} = parse_feature(@feature_with_doc_string)
    assert expected_steps == steps
  end

  test "Reads a table in to the correct step" do
    exptected_table_data = [
      %{:"Column one" => "Hello", :"Column two" => "World"}
    ]
    expected_steps = [
      %Steps.Given{text: "the following table", table_data: exptected_table_data, line: 5},
      %Steps.Then{text: "everything should be okay", line: 8},
    ]
    %{scenarios: [%{steps: steps} | _]} = parse_feature(@feature_with_step_with_table)
    assert expected_steps == steps
  end

  test "Reads Scenario outlines correctly" do
    exptected_example_data = [
      %{start: "12", eat: "5", left: "7"},
      %{start: "20", eat: "5", left: "15"}
    ]
    expected_steps = [
      %Steps.Given{text: "there are <start> cucumbers", line: 4},
      %Steps.When{text: "I eat <eat> cucumbers", line: 5},
      %Steps.Then{text: "I should have <left> cucumbers", line: 6}
    ]
    %{scenarios: [%{steps: steps, examples: examples} | _]} = parse_feature(@feature_with_scenario_outline)
    assert expected_steps == steps
    assert exptected_example_data == examples
  end

  test "Commented out lines are ignored" do
    assert %Feature{scenarios: [%{steps: steps} | _], line: 1} = parse_feature(@feature__with_comments)
    # Only should be 4 steps as the commented out line should be ignored
    assert Enum.count(steps) == 4
  end

  test "file streaming" do
    assert %Gherkin.Elements.Feature{} = File.stream!("test/gherkin/parser/coffee.feature") |> parse_feature()
  end

  test "Reads a feature with a single tag" do
    assert %{tags: [:beverage]} = parse_feature(@feature_with_single_feature_tag)
  end

  test "Reads a feature with a value tag" do
    assert %{tags: [{:cost, 1}]} = parse_feature(@feature_with_value_feature_tag)
  end

  test "Reads a feature with a multiple tags" do
    assert %{tags: [:beverage, :coffee, :caffeine]} = parse_feature(@feature_with_multiple_feature_tag)
  end
end
