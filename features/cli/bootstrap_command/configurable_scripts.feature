Feature: allow additional/configurable bootstrap scripts
  As a user of the motherbrain (MB) command line interface (CLI)
  I need a way to specify the bootstrap template to use
  So I can control the way my nodes are created

  Background:
    Given a valid motherbrain configuration

  Scenario: default template
    Given a cookbook "awesomed" at version "1.2.3" with a plugin that can bootstrap
    When I bootstrap "awesomed"
    Then the exit status should be 0

  Scenario: custom template
    Given a cookbook "awesomed" at version "1.2.3" with a plugin that can bootstrap
    And an extra bootstrap template
    When I bootstrap "awesomed" with the "extra" bootstrap template
    Then the exit status should be 0

  Scenario: named template
    Given a cookbook "awesomed" at version "1.2.3" with a plugin that can bootstrap
    And an installed bootstrap template named "wibble"
    When I bootstrap "awesomed" with the "wibble" bootstrap template
    Then the exit status should be 0

  Scenario: installing template from file
    When I install a template named "foo" from "foo.erb"
    Then the "foo" template should exist

  Scenario: installing template from URL
    When I install a template named "bar" from "http://gist.example.com/bar.gist"
    Then the "bar" template should exist
