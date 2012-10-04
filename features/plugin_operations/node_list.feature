Feature: listing the nodes in a cluster running pvpnet
  As an operator of PvPnet
  I need a way to show me all of the nodes in a cluster
  So I can see every node that comprises a pvpnet cluster and their role in one view

  Scenario: listing the nodes in an environment
    Given the Chef Server has environment "mb-dev"
    And the "mb-dev" environment has a pvpnet cluster with nodes:
      | hostname     | roles                     |
      | node-1.local | activemq_dpa              |
      | node-2.local | activemq_gsm              |
      | node-3.local | activemq_gsm activemq_dpa |
    When I run the pvpnet "nodes" command on the "mb-dev" environment
    Then the output should contain:
      """
      activemq_dpa:
          node-1.local
          node-3.local

      activemq_gsm:
          node-2.local
          node-3.local
      """
    And the exit status should be 0
