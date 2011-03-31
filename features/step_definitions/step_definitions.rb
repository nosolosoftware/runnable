Given /^I have an executable command class$/ do
  @command = Command.new
end

When /^I run the command$/ do
  @command.run
end

Then /^the process has to be running$/ do
  @command.status.should == :running
end

