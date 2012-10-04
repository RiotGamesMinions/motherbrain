Feature: starting a cluster running pvpnet
  As an operator of PvPnet
  I need a way to tell all of the nodes running pvpnet in a particular environment to start their pvpnet services
  So I can easily, quickly, and reliably start a cluster of nodes running pvpnet

  Background: a pvpnet cluster
    Given the Chef Server has environment "mb-dev"
    And the "mb-dev" environment has a pvpnet cluster

  Scenario: sending a start command to a stopped cluster
    Given the pvpnet cluster in "mb-dev" is "stopped"
    When I run the pvpnet "start" command on the "mb-dev" environment
    Then the pvpnet cluster should be "started"
    And the output should contain:
      """
      PvPnet cluster in 'mb-dev' successfully started.
      """
    And the exit status should be 0

  Scenario: sending a start command to a started cluster
  Given the pvpnet cluster in "mb-dev" is "started"
    When I run the pvpnet "start" command on the "mb-dev" environment
    Then the pvpnet cluster should be "started"
    And the output should contain:
      """
      PvPnet cluster in 'mb-dev' is already started. Nothing to do.
      """
    And the exit status should be 0

  Scenario: sending a start command to a cluster that is already executing another command
    Given the pvpnet cluster in "mb-dev" is "busy"
    When I run the pvpnet "start" command on the "mb-dev" environment
    Then the output should contain:
      """
      Could not send start command to PvPnet cluster in 'mb-dev'. Reason: Cluster is busy.
      """
    And the exit status should be the code for error "ClusterBusy"
