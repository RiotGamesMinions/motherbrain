Feature: listing the plugins available to MotherBrain
  As a user of the MotherBrain (MB) command line interface (CLI)
  I need a way to list all of the available plugins and versions
  So I can see what plugins and versions of those plugins I have installed

  Scenario: validate that the configuration exists
    Given a MotherBrain configuration does not exist
    When I run the "version" command
    Then the output should contain:
      """
      No configuration found at:
      """
    And the exit status should be 1

  Scenario: validate that the configuration is valid
    Given an invalid MotherBrain configuration
    When I run the "version" command
    Then the output should contain:
      """
      Invalid Configuration File
      """
    And the exit status should be the code for error "InvalidConfig"
