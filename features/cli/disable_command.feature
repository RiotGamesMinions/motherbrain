Feature: disable a node
  As a user of the motherbrain (MB) command line interface (CLI)
  I want to be able to disable a node
  So that I can keep a node from affecting the live service if it is having problems.
  This will be successfull when all services on the node are stopped and a node is prevented from having chef-client run on it during future motherbrain commands.

  @spawn
  @wip
  Scenario: disable
    Given I have a node named "disableme"
    When I run the "disable" command with:
      | disableme |
    Then the node "disableme" should be disabled
