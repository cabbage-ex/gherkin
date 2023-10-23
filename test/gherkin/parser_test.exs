defmodule Gherkin.ParserTest do
  use ExUnit.Case
  import Gherkin.Parser
  alias Gherkin.Elements.Rule
  alias Gherkin.Elements.Step
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

  @feature_with_scenario_description """
  Feature: Have scenario descriptions

    Scenario: I have a description and a step
      This is the description

      When this step is not part of the description
      Then everything should be okay
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

  @feature_with_step_with_table_containing_pipes ~S"""
  Feature: Have tables
    Sometimes data is a table

    Scenario: I have a step with a table
      Given the following table
      | Column one | Column two              |
      | Hello      | World                   |
      | Goodbye    | It's all\|folks!        |
      | Goodbye    | It's\|all\|folks!       |
      | Goodbye    | Backslash and pipe: \\| |
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

  @feature_with_comments """
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

  @feature_with_rule """
    Feature: Serve coffee
      Coffee should not be served until paid for
      Coffee should not be served until the button has been pressed
      If there is no coffee left then money should be refunded

      Rule: Coffee must be payed for
        Background:
          Given there are 1 coffees left in the machine

        Scenario: Deposit money before buying coffee
          Given I have deposited 1$
          When I press the coffee button
          Then I should be served a coffee

        Scenario: Don't deposit money before buying coffee
          Given I press the coffee button
          Then I should not be served a coffee
  """

  @feature_with_multiple_rules """
    Feature: Barista protocol
      Always greet with a smile
      Always ask for the customer's name

      Rule: In a normal store
        Background:
          Given a customer has approached the till

        Scenario: Customer speaks first
          Given they place an order before Barista can greet
          Then skip greeting and ask name
          And serve with a smile

        Scenario: Barista speaks first
          Given Barista greets first
          Then say common greeting and ask for order and name
          And serve with a smile

      Rule: In the Pentagon
        For security purposes no names can be used at this location

        Background:
          Given a customer has approached the till

        Scenario: Customer speaks first
          Given they place an order before Barista can greet
          Then skip greeting and give customer a unique order number
          And serve with a smile

        Scenario: Barista speaks first
          Given Barista greets first
          Then say common greeting and ask for order and give customer a unique order number
          And serve with a smile
  """

  test "binary and stream is parsed exaclty the same" do
    from_binary =
      "test/fixtures/coffee.feature"
      |> File.read!()
      |> parse_feature()

    from_stream =
      "test/fixtures/coffee.feature"
      |> File.stream!()
      |> parse_feature()

    assert from_binary == from_stream
  end

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

  test "reads in the correct number of scenarios" do
    assert %Feature{scenarios: scenarios, line: 1} = parse_feature(@feature_text)
    assert Enum.count(scenarios) == 2
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
      %Step{keyword: "Given", text: "there are 1 coffees left in the machine", line: 7},
      %Step{keyword: "And", text: "I have deposited 1$", line: 8},
      %Step{keyword: "When", text: "I press the coffee button", line: 9},
      %Step{keyword: "Then", text: "I should be served a coffee", line: 10}
    ]

    %{scenarios: [%{steps: steps} | _]} = parse_feature(@feature_text)
    assert expected_steps == steps
  end

  test "Excludes steps from the scenario descriptions" do
    %{scenarios: [%{description: description, steps: steps}]} =
      parse_feature(@feature_with_scenario_description)

    assert description == """
           This is the description
           """

    assert Enum.count(steps) == 2
  end

  test "Parses the expected background steps" do
    expected_steps = [
      %Step{keyword: "Given", text: "coffee exists as a beverage", line: 7},
      %Step{keyword: "And", text: "there is a coffee machine", line: 8}
    ]

    %{background_steps: background_steps} = parse_feature(@feature_with_backgroundtext)
    assert expected_steps == background_steps
  end

  test "Reads a doc string in to the correct step" do
    expected_data = "{\n  \"a\": \"b\"\n}\n"

    expected_steps = [
      %Step{keyword: "Given", text: "the following data", doc_string: expected_data, line: 5},
      %Step{keyword: "Then", text: "everything should be okay", line: 11}
    ]

    %{scenarios: [%{steps: steps} | _]} = parse_feature(@feature_with_doc_string)
    assert expected_steps == steps
  end

  test "Reads a table in to the correct step" do
    expected_table_data = [
      %{:"Column one" => "Hello", :"Column two" => "World"}
    ]

    expected_steps = [
      %Step{
        keyword: "Given",
        text: "the following table",
        table_data: expected_table_data,
        line: 5
      },
      %Step{keyword: "Then", text: "everything should be okay", line: 8}
    ]

    %{scenarios: [%{steps: steps} | _]} = parse_feature(@feature_with_step_with_table)
    assert expected_steps == steps
  end

  test "Reads in a table containing pipes to the correct step" do
    expected_table_data = [
      %{:"Column one" => "Hello", :"Column two" => "World"},
      %{:"Column one" => "Goodbye", :"Column two" => "It's all|folks!"},
      %{:"Column one" => "Goodbye", :"Column two" => "It's|all|folks!"},
      %{:"Column one" => "Goodbye", :"Column two" => "Backslash and pipe: \\|"}
    ]

    expected_steps = [
      %Step{
        keyword: "Given",
        text: "the following table",
        table_data: expected_table_data,
        line: 5
      },
      %Step{keyword: "Then", text: "everything should be okay", line: 11}
    ]

    %{scenarios: [%{steps: steps} | _]} =
      parse_feature(@feature_with_step_with_table_containing_pipes)

    assert expected_steps == steps
  end

  test "Reads Scenario outlines correctly" do
    expected_example_data = [
      %{start: "12", eat: "5", left: "7"},
      %{start: "20", eat: "5", left: "15"}
    ]

    expected_steps = [
      %Step{keyword: "Given", text: "there are <start> cucumbers", line: 4},
      %Step{keyword: "When", text: "I eat <eat> cucumbers", line: 5},
      %Step{keyword: "Then", text: "I should have <left> cucumbers", line: 6}
    ]

    %{scenarios: [%{steps: steps, examples: examples} | _]} =
      parse_feature(@feature_with_scenario_outline)

    assert expected_steps == steps
    assert expected_example_data == examples
  end

  test "Commented out lines are ignored" do
    assert %Feature{scenarios: [%{steps: steps} | _], line: 1} =
             parse_feature(@feature_with_comments)

    # Only should be 4 steps as the commented out line should be ignored
    assert Enum.count(steps) == 4
  end

  test "file streaming" do
    assert %Gherkin.Elements.Feature{} =
             File.stream!("test/fixtures/coffee.feature") |> parse_feature()
  end

  test "Reads a feature with a single tag" do
    assert %{tags: [:beverage]} = parse_feature(@feature_with_single_feature_tag)
  end

  test "Reads a feature with a value tag" do
    assert %{tags: [{:cost, 1}]} = parse_feature(@feature_with_value_feature_tag)
  end

  test "Reads a feature with a multiple tags" do
    assert %{tags: [:beverage, :coffee, :caffeine]} =
             parse_feature(@feature_with_multiple_feature_tag)
  end

  test "Reads a feature with a rule" do
    assert %{rules: [%Rule{} = _]} = parse_feature(@feature_with_rule)
  end

  test "Reads a feature with multiple rules" do
    assert %{rules: [%Rule{}, %Rule{}]} = parse_feature(@feature_with_multiple_rules)
  end
end
