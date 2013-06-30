Feature: listing the plugins available to motherbrain
  As a user of the motherbrain command line interface
  I need a way to list all of the available plugins and versions
  So I can see what plugins and versions of those plugins I have installed

  Background:
    Given a valid motherbrain configuration
    And I have an empty Berkshelf
    And the Chef Server is empty

  Scenario: listing all plugins
    Given a cookbook "pvpnet" at version "1.2.3" with a plugin
    And a cookbook "pvpnet" at version "2.3.4" with a plugin
    And a cookbook "league" at version "1.0.0" with a plugin
    When I run the "plugin list" command
    Then the output should contain:
      """

      ** listing installed plugins...

      pvpnet: 1.2.3, 2.3.4
      league: 1.0.0
      """
    And the exit status should be 0

  Scenario: listing plugins when there are no plugins installed
    When I run the "plugin list" command
    Then the output should contain:
      """
      No plugins found in your Berkshelf:
      """
    And the exit status should be 0

  Scenario: listing remote plugins
    Given a cookbook on the Chef Server "ruby" at version "1.2.3" with a plugin
    And a cookbook on the Chef Server "elixir" at version "2.0.0" with a plugin
    When I run the "plugin list" command with:
      | --remote |
    Then the output should contain:
      """
      ** listing installed and remote plugins...

      ruby: 1.2.3
      elixir: 2.0.0
      """
    And the exit status should be 0
