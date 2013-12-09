Feature: Creating an environment from file
  As a mb user
  I can create an environment via motherbrain from a file
  So I can manage an environment without using other tools such as knife

  Background:
    Given there is a file from input named "spec/fixtures/test_env.json"

  @focus
  @chef_server
  Scenario: Create an environment from file
    When I create an environment from file "spec/fixtures/test_env.json"
    Then the exit status should be 0
    And there should be an environment "test_env" on the chef server

  @focus
  @chef_server
  Scenario: Creating an existing environment
    Given there is an environment on the chef server named "test_env"
    When I create an environment from file "spec/fixtures/test_env.json"
    Then the output should contain:
      """
      Environment already exists.
      """
    And the exit status should be the code for error "EnvironmentExists"
    And there should be an environment "test_env" on the chef server
