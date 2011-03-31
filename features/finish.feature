Feature: Check if a command return the correct code error

  As a developer who uses runnable
  I want to check if a process finished correctly
  In order to be able to warn about it

  Scenario: Command Finish correctly
    Given "ls -alh" is running
    When "ls -alh" finish
    Then "ls -alh" should return 0

  Scenario: Command Finish anormally
    Given "ls -option" is running
    When "ls -option" finish
    Then "ls -option" should not return 0


