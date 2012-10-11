Feature: listing the plugins available to MotherBrain
  As a user of the MotherBrain (MB) command line interface (CLI)
  I need a way to list all of the available plugins and versions
  So I can see what plugins and versions of those plugins I have installed

  Background:
    Given a valid MotherBrain configuration

  Scenario: listing all plugins
    Given a plugin "pvpnet" at version "1.2.3"
    And a plugin "pvpnet" at version "2.3.4"
    And a plugin "league" at version "1.0.0"
    When I run the "plugins" command
    Then the output should contain:
      """
      league: 1.0.0
      pvpnet: 2.3.4, 1.2.3
      """
    And the exit status should be 0

  Scenario: listing plugins when there are no plugins installed
    Given I have no plugins
    When I run the "plugins" command
    Then the output should contain:
      """
      No MotherBrain plugins found in any of your configured plugin paths!

      Paths: 
      """
    And the exit status should be 0
