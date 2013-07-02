Feature: Limiting plugin commands to a subset of nodes
  As an end-user of a motherbrain plugin
  I want to be able to limit plugin commands to a subset of matching nodes
  So I can selectively manage my infrastucture.
 
   * Can specify one or more hostnames or IP addresses
   * Can specify a range of IPs
   * Maybe can specify a regex for hostname matches

  Background:
    Given a cookbook "foo" with a plugin command "bar" that affects 3 nodes

  @spawn
  Scenario: limiting to a single node by full host + domain
    When I run the "foo bar --only node1.example.com" command
    Then the output should contain "Limiting to 1 node(s)"
    And the exit status should be 0

  @spawn
  Scenario: limiting to a single node by host only
    When I run the "foo bar --only node1" command
    Then the output should contain "Limiting to 1 node(s)"
    And the exit status should be 0

  @spawn
  Scenario: limiting to a single node by IP
    When I run the "foo bar --only 192.168.1.1" command
    Then the output should contain "Limiting to 1 node(s)"
    And the exit status should be 0

  @spawn
  Scenario: limiting to a set of nodes by full host + domain
    When I run the "foo bar --only node1.example.com,node2.example.com" command
    Then the output should contain "Limiting to 2 node(s)"
    And the exit status should be 0

  @spawn
  Scenario: limiting to a set of nodes by host only
    When I run the "foo bar --only node1,node2" command
    Then the output should contain "Limiting to 2 node(s)"
    And the exit status should be 0

  @spawn
  Scenario: limiting to a set of nodes by IP
    When I run the "foo bar --only 192.168.1.1,192.168.1.2" command
    Then the output should contain "Limiting to 2 node(s)"
    And the exit status should be 0

  @spawn
  Scenario: limiting to a set of nodes by IP range
    When I run the "foo bar --only 192.168.1.1-2" command
    Then the output should contain "Limiting to 2 node(s)"
    And the exit status should be 0

