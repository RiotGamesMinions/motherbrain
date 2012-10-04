Feature: stopping a cluster running pvpnet
  As an operator of PvPnet
  I need a way to tell all of the nodes running pvpnet in a particular environment to stop their pvpnet services
  So I can easily, quickly, and reliably stop a cluster of nodes running pvpnet

  Scenario: sending a stop command to a started cluster
    Given a pvpnet cluster in environment "mb-dev"
    And the pvpnet cluster in "mb-dev" is "started"
    When I run the pvpnet "stop" command on the "mb-dev" environment
    Then the pvpnet cluster should be "stopped"
    And the output should contain:
      """
      Cluster in 'mb-dev' successfully stopped.
      """
    And the exit status should be 0

  Scenario: sending a stop command to a stopped cluster
    Given a pvpnet cluster in environment "mb-dev"
    And the pvpnet cluster in "mb-dev" is "stopped"
    When I run the pvpnet "stop" command on the "mb-dev" environment
    Then the pvpnet cluster should be "stopped"
    And the output should contain:
      """
      Cluster in 'mb-dev' is already stopped. Nothing to do.
      """
    And the exit status should be 0

  Scenario: sending a stop command to a cluster that is already executing another command
    Given a pvpnet cluster in environment "mb-dev"
    And the pvpnet cluster in "mb-dev" is "busy"
    When I run the pvpnet "stop" command on the "mb-dev" environment
    Then the output should contain:
      """
      Could not send stop command to cluster in 'mb-dev'. Reason: Cluster is busy.
      """
    And the exit status should be the code for error "ClusterBusy"
