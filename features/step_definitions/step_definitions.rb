Given /^I have create a command$/ do
  @my_command = Command.new( "ls" )
end

When /^I invoke the commad$/ do
  @my_command.run
end

Then /^the system should run the command$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^I the pid has to be set to pid's system command$/ do
  pending # express the regexp above with the code you wish you had
end


