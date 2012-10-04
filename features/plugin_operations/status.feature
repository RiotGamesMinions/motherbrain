Feature: getting the status of a cluster running pvpnet
  As an operator of PvPnet
  I need a way to query all of the nodes running pvpnet in a particular environment about their status
  So I know if an update is taking place and the current state of the cluster

  @wip
  Scenario: sending a status command to a started cluster
    Given a pvpnet cluster in environment "mb-dev"
    And the pvpnet cluster in "mb-dev" is "started"
    When I run the pvpnet "status" command on the "mb-dev" environment
    And the output should contain:
      """
      PvPnet Cluster: 'mb-dev'
      Status: 'started'
      """
    And the exit status should be 0

  @wip
  Scenario: sending a status command to a stopped cluster
    Given a pvpnet cluster in environment "mb-dev"
    And the pvpnet cluster in "mb-dev" is "stopped"
    When I run the pvpnet "status" command on the "mb-dev" environment
    And the output should contain:
      """
      PvPnet Cluster: 'mb-dev'
      Status: 'stopped'
      """
    And the exit status should be 0

  @wip
  Scenario: sending a status command to a cluster that is starting
    Given a pvpnet cluster in environment "mb-dev"
    And the pvpnet cluster in "mb-dev" is "starting"
    When I run the pvpnet "status" command on the "mb-dev" environment
    And the output should contain:
      """
      PvPnet Cluster: 'mb-dev'
      Status: 'starting'
      """
    And the exit status should be 0

  @wip
  Scenario: sending a status command to a cluster that is stopping
    Given a pvpnet cluster in environment "mb-dev"
    And the pvpnet cluster in "mb-dev" is "stopping"
    When I run the pvpnet "status" command on the "mb-dev" environment
    And the output should contain:
      """
      PvPnet Cluster: 'mb-dev'
      Status: 'stopping'
      """
    And the exit status should be 0
