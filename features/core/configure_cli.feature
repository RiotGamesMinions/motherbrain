Feature: configuring the MotherBrain (MB) command line interface (CLI)
  As a user of the MotherBrain (MB) command line interface (CLI)
  I need a way to configure my MB CLI based on answers I provide to a set of questions
  So it is quick and easy for me to configure or reconfigure my MB CLI

  Scenario: generating a new config file
    Given a MotherBrain configuration does not exist
    When I run the "configure" command interactively
    And I type "https://api.opscode.com/organizations/vialstudio"
    And I type "reset"
    And I type "/Users/reset/.chef/reset.pem"
    And I type "root"
    And I type "secretpass"
    Then the output should contain:
      """
      Config written to:
      """
    And the exit status should be 0
    And a MotherBrain config file should exist and contain:
      | chef.api_url     | https://api.opscode.com/organizations/vialstudio |
      | chef.api_client  | reset                                            |
      | chef.api_key     | /Users/reset/.chef/reset.pem                     |
      | ssh.user         | root                                             |
      | ssh.password     | secretpass                                       |

  Scenario: attempting to generate a new config when one already exists
    Given a valid MotherBrain configuration
    When I run the "configure" command interactively
    Then the output should contain:
      """
      A configuration file already exists. Re-run with the --force flag if you wish to overwrite it.
      """
    And the exit status should be the code for error "ConfigExists"

  Scenario: forcefully generating a config when one already exists
    Given a valid MotherBrain configuration
    When I run the "configure" command interactively with:
      | --force |
    And I type "https://api.opscode.com/organizations/vialstudio"
    And I type "reset"
    And I type "/Users/reset/.chef/reset.pem"
    And I type "root"
    And I type "secretpass"
    Then the output should contain:
      """
      Config written to:
      """
    And the exit status should be 0
    And a MotherBrain config file should exist and contain:
      | chef.api_url     | https://api.opscode.com/organizations/vialstudio |
      | chef.api_client  | reset                                            |
      | chef.api_key     | /Users/reset/.chef/reset.pem                     |
      | ssh.user         | root                                             |
      | ssh.password     | secretpass                                       |
