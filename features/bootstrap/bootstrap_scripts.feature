Feature: allow additional/configurable bootstrap scripts
  As a user of the MotherBrain (MB) command line interface (CLI)
  I need a way to specify the bootstrap template to use
  So I can control the way my nodes are created

  Background:
    Given a valid MotherBrain configuration

  Scenario: default template
    Given a cookbook "awesomed" at version "1.2.3" with a plugin that can bootstrap
    When I bootstrap "awesomed"
    Then the exit status should be 0

  @ivey
  Scenario: custom template
    Given a cookbook "awesomed" at version "1.2.3" with a plugin that can bootstrap
    And an extra bootstrap template
    When I bootstrap "awesomed" with the extra bootstrap template
    Then the exit status should be 0

