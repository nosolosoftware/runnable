Feature: Check if a command finish correctly

  As a developer who uses runnable
  I want to check if a process finished correctly
  In order to be able to warn about it

  Scenario: Command Finish correctly
    Given a command is running
    When a command finish with 0
    Then a command finish correctly

  Scenario: Command Finish anormally
    Given a command is running
    When a command finish with something but 0
    Then a command finish anormally

