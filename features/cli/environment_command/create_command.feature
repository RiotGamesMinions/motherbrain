Feature: Creating an environment
  As a mb user
  I can create an environment via motherbrain
  So I can manage an environment without using other tools such as knife

  @chef_server
  Scenario: Create an environment
    Given there is not an environment on the chef server named "test_env"
    When I create an environment named "test_env"
    Then the exit status should be 0
    And there should be an environment "test_env" on the chef server

  @chef_server
  Scenario: Creating an existing environment
    Given there is an environment on the chef server named "test_env"
    When I create an environment named "test_env"
    Then the output should contain:
      """
      An environment named 'test_env' already exists in the Chef Server.
      """
    And the exit status should be the code for error "EnvironmentExists"
    And there should be an environment "test_env" on the chef server
