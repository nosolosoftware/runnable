Feature: running command
  As a programmer
  I want my class to run a command
  So I can interact with the system
  
  Scenario: execute a command valid to the system
    Given I have create a command
    When I invoke the commad
    Then the system should run the command
    And I the pid has to be set to pid's system command
