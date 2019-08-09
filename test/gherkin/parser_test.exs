defmodule Gherkin.ParserTest do
  use ExUnit.Case
  alias Gherkin.Parser
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
      |> Parser.parse()

    from_stream =
      "test/fixtures/coffee.feature"
      |> File.stream!()
      |> Parser.parse()

    assert "test/fixtures/coffee.feature" == from_stream.file
    assert from_binary == Map.put(from_stream, :file, nil)
  end

  test "Parses the feature text" do
    assert %Feature{text: "Serve coffee", line: 1} = Parser.parse(@feature_text)
  end

  test "Parses the feature description" do
    assert %Feature{description: description, line: 1} = Parser.parse(@feature_text)

    assert description ==
             "Coffee should not be served until paid for\nCoffee should not be served until the button has been pressed\nIf there is no coffee left then money should be refunded"
  end

  test "reads in the correct number of scenarios" do
    assert %Feature{scenarios: scenarios, line: 1} = Parser.parse(@feature_text)
    assert Enum.count(scenarios) == 2
  end

  test "Gets the scenario's name" do
    assert %Feature{scenarios: [%{text: text} | _], line: 1} = Parser.parse(@feature_text)
    assert text == "Buy last coffee"
  end

  test "Gets the correct number of steps for the scenario" do
    assert %Feature{scenarios: [%{steps: steps} | _], line: 1} = Parser.parse(@feature_text)
    assert Enum.count(steps) == 4
  end

  test "Has the correct steps for a scenario" do
    assert %{scenarios: [%{steps: steps} | _]} = Parser.parse(@feature_text)

    assert [
             %Step{type: :given, text: "there are 1 coffees left in the machine", line: 7},
             %Step{type: :and, text: "I have deposited 1$", line: 8},
             %Step{type: :when, text: "I press the coffee button", line: 9},
             %Step{type: :then, text: "I should be served a coffee", line: 10}
           ] = steps
  end

  test "Parses the expected background steps" do
    assert %{background: %{steps: background_steps}} = Parser.parse(@feature_with_backgroundtext)

    assert [
             %Step{type: :given, text: "coffee exists as a beverage", line: 7},
             %Step{type: :and, text: "there is a coffee machine", line: 8}
           ] = background_steps
  end

  test "Reads a doc string in to the correct step" do
    expected_data = "{\n  \"a\": \"b\"\n}"

    expected_steps = %{scenarios: [%{steps: steps} | _]} = Parser.parse(@feature_with_doc_string)

    assert [
             %Step{type: :given, text: "the following data", doc_string: expected_data, line: 5},
             %Step{type: :then, text: "everything should be okay", line: 11}
           ] = steps
  end

  test "Reads a table in to the correct step" do
    assert %{scenarios: [%{steps: steps} | _]} = Parser.parse(@feature_with_step_with_table)

    assert [
             %Step{
               type: :given,
               text: "the following table",
               data_table: [
                 %{:"Column one" => "Hello", :"Column two" => "World"}
               ],
               line: 5
             },
             %Step{type: :then, text: "everything should be okay", line: 8}
           ] = steps
  end

  test "Reads Scenario outlines correctly" do
    assert %{scenarios: [%{steps: steps, examples: examples} | _]} =
             Parser.parse(@feature_with_scenario_outline)

    assert [
             %Step{type: :given, text: "there are <start> cucumbers", line: 4},
             %Step{type: :when, text: "I eat <eat> cucumbers", line: 5},
             %Step{type: :then, text: "I should have <left> cucumbers", line: 6}
           ] = steps

    assert [
             %{start: "12", eat: "5", left: "7"},
             %{start: "20", eat: "5", left: "15"}
           ] = examples
  end

  test "Commented out lines are ignored" do
    assert %Feature{scenarios: [%{steps: steps} | _], line: 1} =
             Parser.parse(@feature_with_comments)

    # Only should be 4 steps as the commented out line should be ignored
    assert Enum.count(steps) == 4
  end

  test "file streaming" do
    assert %Gherkin.Elements.Feature{} =
             File.stream!("test/fixtures/coffee.feature") |> Parser.parse()
  end

  test "Reads a feature with a single tag" do
    assert %{tags: [:beverage]} = Parser.parse(@feature_with_single_feature_tag)
  end

  test "Reads a feature with a value tag" do
    assert %{tags: [{:cost, 1}]} = Parser.parse(@feature_with_value_feature_tag)
  end

  test "Reads a feature with a multiple tags" do
    assert %{tags: [:beverage, :coffee, :caffeine]} =
             Parser.parse(@feature_with_multiple_feature_tag)
  end

  test "Reads a feature with a rule" do
    assert %{rules: [%Rule{} = _]} = Parser.parse(@feature_with_rule)
  end

  test "Reads a feature with multiple rules" do
    assert %{rules: [%Rule{}, %Rule{}]} = Parser.parse(@feature_with_multiple_rules)
  end
end
