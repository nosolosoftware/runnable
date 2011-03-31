Given /^"([^"]*)" is running$/ do |arg1|
  # express the regexp above with the code you wish you had
  
  class Command < Runnable
  end


  @command = Mock.new ( 'command' )

  

end

When /^"([^"]*)" finish$/ do |arg1|
    pending # express the regexp above with the code you wish you had
end

Then /^"([^"]*)" should return (\d+)$/ do |arg1, arg2|
    pending # express the regexp above with the code you wish you had
end

Then /^"([^"]*)" should not return (\d+)$/ do |arg1, arg2|
    pending # express the regexp above with the code you wish you had
end

