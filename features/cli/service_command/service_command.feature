Feature: dynamic commands for managing service state
  As a motherbrain plugin author using the service orchestration pattern
  I want to manage the state of my service using a dedicated command
  So that I don't have lots of duplicated commands in my plugin
  
  Background:
    Given a valid motherbrain configuration
    
  Scenario: listing the command
    Given a cookbook "awesomed" at version "1.2.3" with a plugin that can bootstrap
    When I run the "awesomed service -e Foo" command
    Then the output should contain:
      """
      Usage: "mb service [COMPONENT].[SERVICE] [STATE]".
      """
    And the exit status should be 1

  Scenario: Get a service to start
    Given a cookbook "awesomed" at version "1.2.3" with a plugin that can bootstrap
    When I create an environment named "test_env"
    And I run the "awesomed service app.tomcat start -e test_env" command
