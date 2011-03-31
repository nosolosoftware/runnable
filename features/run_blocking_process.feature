Feature: running a blocking process
  As a programmer
  I want my class to start a running blocking process
  So I can execute the process from a class
  
  Scenario: execute a blocking process
    Given I have an executable command class
    When I run the command
    Then the process has to be running
