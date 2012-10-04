Feature: recovering from cluster not found errors when sending cluster operations
  As a user of the MotherBrain (MB) command line interface (CLI)
  I need to receive a friendly error message and unique exit status code if the target environment does not contain a PvPnet cluster
  So I know why my command failed and can automate what to do in case of a failure

  Background: no pvpnet cluster
    Given the Chef Server has environment "mb-dev"
    But the "mb-dev" environment does not have a pvpnet cluster

  @wip
  Scenario Outline: sending a command to an environment that does not contain a cluster
    Given an environment "mb-dev" that does not contain a pvpnet cluster
    When I run the pvpnet "<command_name>" command on the "mb-dev" environment with "<arguments>"
    Then the output should contain:
      """
      No PvPnet cluster found in the 'mb-dev' environment.
      """
    And the exit status should be the code for error "ClusterNotFound"

    Scenarios:
      | command_name | arguments |
      | start        |           |
      | stop         |           |
      | status       |           |
      | update       | 1.60.1    |
