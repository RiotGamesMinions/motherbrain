Feature: Creating an environment from file
  As a mb user
  I can create an environment via motherbrain from a file
  So I can manage an environment without using other tools such as knife

  Background:
    Given there is a file from input named "spec/fixtures/test_env.json"

  @chef_server
  Scenario: Create an environment from file
    Given there is not an environment on the chef server named "test_env"
    When I create an environment from file "spec/fixtures/test_env.json"
    Then the exit status should be 0
    And there should be an environment "test_env" on the chef server

  @chef_server
  Scenario: Creating an existing environment from file
    Given there is an environment on the chef server named "test_env"
    When I create an environment from file "spec/fixtures/test_env.json"
    Then the output should contain:
      """
      An environment named 'test_env' already exists in the Chef Server.
      """
    And the exit status should be the code for error "EnvironmentExists"
    And there should be an environment "test_env" on the chef server




