Feature: recovering from incorrect permissions when when sending cluster operations
  As a user of the MotherBrain (MB) command line interface (CLI)
  I need to receive a friendly error message and unique exit status code if the environment is not found in the Chef Server
  So I know why my command failed and can automate what to do in case of a failure

  Background: missing environment on Chef Server
    Given the Chef Server does not have the environment "mb-dev"

  @wip
  Scenario Outline: sending a command when the Chef Server is offline or unavailable
    When I run the pvpnet "<command_name>" command on the "mb-dev" environment with "<arguments>"
    Then the output should contain:
      """
      No environment named 'mb-dev' found.
      """
    And the exit status should be the code for error "EnvironmentNotFound"

    Scenarios:
      | command_name | arguments |
      | start        |           |
      | stop         |           |
      | status       |           |
      | update       | 1.60.1    |
