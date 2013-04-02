Feature: listing the plugins available to MotherBrain
  As a user of the MotherBrain (MB) command line interface (CLI)
  I need a way to list all of the available plugins and versions
  So I can see what plugins and versions of those plugins I have installed

  Background:
    Given a valid MotherBrain configuration
    And I have an empty Berkshelf

  Scenario: listing all plugins
    Given a cookbook "pvpnet" at version "1.2.3" with a plugin
    And a cookbook "pvpnet" at version "2.3.4" with a plugin
    And a cookbook "league" at version "1.0.0" with a plugin
    When I run the "plugins" command
    Then the output should contain:
      """
      
      ** listing local plugins...

      league: 1.0.0
      pvpnet: 2.3.4, 1.2.3
      """
    And the exit status should be 0

  Scenario: listing plugins when there are no plugins installed
    Given I have an empty Berkshelf
    When I run the "plugins" command
    Then the output should contain:
      """
      No plugins found in your Berkshelf:
      """
    And the exit status should be 0
