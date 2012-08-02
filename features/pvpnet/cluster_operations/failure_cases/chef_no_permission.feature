Feature: recovering from incorrect permissions when when sending cluster operations
  As a user of the MotherBrain (MB) command line interface (CLI)
  I need to receive a friendly error message and unique exit status code if my client does not have proper permissionsd
  So I know why my command failed and can automate what to do in case of a failure

  Background: no permissions
    Given the Chef Server has environment "mb-dev"
    And I do not have admin permissions on the Chef Server

  Scenario Outline: sending a command when you do not have permissions on the Chef Server    
    When I run the pvpnet "<command_name>" command on the "mb-dev" environment with "<arguments>"
    Then the output should contain:
      """
      You do not have the proper permissions on the Chef Server
      """
    And the exit status should be the code for error "ChefPermissionsError"

    Scenarios:
      | command_name | arguments |
      | start        |           |
      | stop         |           |
      | status       |           |
      | update       | 1.60.1    |
