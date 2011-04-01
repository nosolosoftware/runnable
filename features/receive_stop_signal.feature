Feature: receive a signal when command procces ends
  As a programmer who uses runnable
  I want to receive a signal when the command process ends
  So I can be sure that a command process has end
  
  Scenario: receive a signal from a process
    Given I have the command process "sleep 5"
    When the process ends
    And enough time has passed since process start his execution
    Then I should receive a "stop" signal
    And I should receive the termination state of the process