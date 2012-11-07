Feature: running the MotherBrain (MB) command line interface (CLI)
  As a user of the MotherBrain (MB) command line interface (CLI)
  I'd like to see certain output
  So that I have some direction in how to use MB

  Scenario: running with no command and no configuration
    Given a MotherBrain configuration does not exist
    When I run MB with no arguments
    Then the output should contain:
      """
      Tasks:
      """
    And the output should not contain:
      """
      No configuration found
      """
    And the exit status should be 0

