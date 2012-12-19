Feature: recovering from incorrect permissions when when sending cluster operations
  As a user of the MotherBrain (MB) command line interface (CLI)
  I need to receive a friendly error message and unique exit status code if the Chef Server is unavailble
  So I know why my command failed and can automate what to do in case of a failure

  Background: chef server unavailable
    Given the Chef Server is unavailable

  @wip
  Scenario Outline: sending a command when the Chef Server is offline or unavailable
    When I run the pvpnet "<command_name>" command on the "mb-dev" environment with "<arguments>"
    Then the output should contain:
      """
      Error connecting to Chef Server:
      """
    And the exit status should be the code for error "ChefConnectionError"

    Scenarios:
      | command_name | arguments |
      | start        |           |
      | stop         |           |
      | status       |           |
      | update       | 1.60.1    |
