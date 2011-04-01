Feature: send signals to a process
  As a programmer who uses runnable
  I want to send signals to the command process
  So I can stop or destroy it
  
  Scenario: Send a stop signal to a blocking command process
    Given I create a "grep" command process
    When I send the "stop" signal
    Then the process should exist
    And the process should be stopped
    
  Scenario: Send a kill signal to a blocking command process
    Given I create a "grep" command process
    When I send the "kill" signal
    Then the process should not exist