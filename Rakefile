require 'rake'
require 'yard'
require 'cucumber'
require 'cucumber/rake/task'
require 'rspec/core/rake_task'

YARD::Rake::YardocTask.new('doc') do |t|
  t.files = ['lib/**/*.rb']
end 

Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = ["./features"] 
end

RSpec::Core::RakeTask.new(:rspec) do |t|
  t.rspec_opts = ["--format doc", "--color"]
end
