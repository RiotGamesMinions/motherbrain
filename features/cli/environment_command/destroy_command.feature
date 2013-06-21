Feature: Destroying an environment
  As a mb user
  I can destroy an environment via motherbrain
  So I can manage an environment without using other tools such as knife

  Background:
    Given there is an environment on the chef server named "destroy_me"
    And we have AWS credentials

  @chef_server
  Scenario: Destroying an environment
    When I destroy the environment "destroy_me"
    Then the exit status should be 0
    And there should not be an environment "destroy_me" on the chef server

  @chef_server
  Scenario: Destroying a locked environment
    Given the environment "destroy_me" is locked
    When I destroy the environment "destroy_me"
    Then the output should contain:
      """
      The environment "destroy_me" is locked. You may use --force to override this safeguard.
      """
    And the exit status should be the code for error "ResourceLocked"
    And there should be an environment "destroy_me" on the chef server

  @chef_server
  Scenario: Destroying a locked environment with --force
    Given the environment "destroy_me" is locked
    When I destroy the environment "destroy_me" with flags:
      | --force   |
    Then the exit status should be 0
    And there should not be an environment "destroy_me" on the chef server
