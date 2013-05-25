Feature: installing custom bootstrap templates
  As a user of the motherbrain CLIGateway
  I need a way to install custom bootstrap templates
  So I can use a different template for bootstrapping

Scenario: installing a template that does not exist
  Given I have no templates installed
  When I run `mb template my_template http://does.not.exist.com`
  Then the exit status should be the code for error "BootstrapTemplateNotFound"
  And I should have no templates installed
