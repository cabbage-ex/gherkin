defmodule Gherkin.GherkinTest do
  use ExUnit.Case

  test "parsing" do
    assert %Gherkin.Elements.Feature{scenarios: _scenarios} = File.read!("test/gherkin/parser/coffee.feature") |> Gherkin.parse
  end

  @outline """
  Feature: Serve coffee

    Scenario Outline: Buy coffee
      Given there are <coffees> coffees left in the machine
      And I have deposited $<money>
      When I press the coffee button
      Then I should be served <served> coffees

    Examples:
      | coffees | money | served |
      |  12     |  6    |  12    |
      |  2      |  3    |  2     |
  """

  test "changing an outline into a scenario" do
    feature = @outline |> Gherkin.parse
    assert [%Gherkin.Elements.Scenario{
      name: "Buy coffee (Example 1)",
      steps: [
        %Gherkin.Elements.Steps.Given{text: "there are 12 coffees left in the machine"},
        %Gherkin.Elements.Steps.And{text: "I have deposited $6"},
        %Gherkin.Elements.Steps.When{text: "I press the coffee button"},
        %Gherkin.Elements.Steps.Then{text: "I should be served 12 coffees"}
      ]
    }, %Gherkin.Elements.Scenario{
      name: "Buy coffee (Example 2)",
      steps: [
        %Gherkin.Elements.Steps.Given{text: "there are 2 coffees left in the machine"},
        %Gherkin.Elements.Steps.And{text: "I have deposited $3"},
        %Gherkin.Elements.Steps.When{text: "I press the coffee button"},
        %Gherkin.Elements.Steps.Then{text: "I should be served 2 coffees"}
      ]
    }] = Gherkin.scenarios_for(feature.scenarios |> hd)
  end

  test "flattening a feature into scenarios" do
    feature = @outline |> Gherkin.parse
    assert %Gherkin.Elements.Feature{scenarios: [%Gherkin.Elements.Scenario{}, %Gherkin.Elements.Scenario{}]} = Gherkin.flatten(feature)
  end
end
