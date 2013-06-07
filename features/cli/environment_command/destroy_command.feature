Feature: Destroying an environment
  As a mb user
  I can destroy an environment via motherbrain
  So I can manage an environment without using other tools such as knife

  Background:
    Given we have a Chef server at "127.0.0.1:28889"
    And we have AWS credentials
    And there is an environment on the chef server named "destroy_me"

  @chef_server
  Scenario Outline: Destroying an environment
    When I destroy the environment "destroy_me" using the "<provisioner>" provisioner
    Then there should not be an environment "destroy_me" on the chef server

  Examples:
    | provisioner         |
    | aws                 |
    | environment_factory |

  @chef_server
  Scenario: Destroying a locked environment
    Given the environment "destroy_me" is locked
    When I destroy the environment "destroy_me"
    Then there should be an environment "destroy_me" on the chef server
    And the output should contain:
      """
      The environment "destroy_me" is locked. You may use --force to override this safeguard.
      """

  @chef_server
  Scenario: Destroying a locked environment with --force
    Given the environment "destroy_me" is locked
    When I destroy the environment "destroy_me" with flags:
      | --force |
    Then there should not be an environment "destroy_me" on the chef server
