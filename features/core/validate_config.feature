Feature: listing the plugins available to MotherBrain
  As a user of the MotherBrain (MB) command line interface (CLI)
  I need a way to list all of the available plugins and versions
  So I can see what plugins and versions of those plugins I have installed

  Scenario: validate that the configuration exists
    Given a MotherBrain configuration does not exist
    When I run a command that requires a config
    Then the output should contain:
      """
      No configuration found at:
      """
    And the exit status should be 1

  Scenario: validate that the configuration is valid
    Given an invalid MotherBrain configuration
    When I run a command that requires a config
    Then the output should contain:
      """
      Invalid Configuration File
      """
    And the exit status should be the code for error "InvalidConfig"

  Scenario: asking for help with an invalid or non existent canfiguration file
    Given an invalid MotherBrain configuration
    When I run the "help" command
    Then the exit status should be 0

  Scenario: getting version information with an invalid configuration file
    Given an invalid MotherBrain configuration
    When I run the "version" command
    Then the exit status should be 0

  Scenario: configuring with an invalid configuration file
    Given an invalid MotherBrain configuration
    When I run the "configure" command interactively with:
      | --force |
    And I type "https://api.opscode.com/organizations/vialstudio"
    And I type "reset"
    And I type "/Users/reset/.chef/reset.pem"
    And I type "http://nexus.riotgames.com/nexus/"
    And I type "riot"
    And I type "deployer"
    And I type "secr3tPassw0rd"
    And I type "root"
    And I type "secretpass"
    And the exit status should be 0
