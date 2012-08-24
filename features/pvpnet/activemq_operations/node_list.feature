Feature: bootstrapping nodes to an existing cluster
  As an operator of PvPnet
  I need a command to list all of the ActiveMQ nodes in a cluster
  So I can see every ActiveMQ node in one view

  Scenario: listing the nodes in an environment
    Given the Chef Server has environment "mb-dev"
    And the "mb-dev" environment has a pvpnet cluster with nodes:
      | hostname     | roles                     |
      | node-1.local | activemq_dpa              |
      | node-2.local | activemq_gsm              |
      | node-3.local | activemq_gsm activemq_dpa |
    When I run the pvpnet activemq "nodes" command on the "mb-dev" environment
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
