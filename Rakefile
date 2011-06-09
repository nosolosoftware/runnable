# encoding: utf-8
require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rake'

require 'yard'
YARD::Rake::YardocTask.new('doc') do |t|
  t.files = ['lib/runnable.rb', 'lib/runnable/command_parser.rb', 'lib/runnable/gnu.rb', 'lib/runnable/extended.rb']
  t.options = ['-m','markdown', '-r' , 'README.markdown']
end 

require 'cucumber'
require 'cucumber/rake/task'
Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = ["./features"] 
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:rspec) do |t|
  t.rspec_opts = ["--format doc", "--color"]
end

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more     options
  gem.name = 'runnable'
  gem.homepage = 'http://github.com/nosolosoftware/runnable'
  gem.license = 'GPL-3'
  gem.summary = %Q{A Ruby gem for execute and control system commands}
  gem.description = %Q{Convert a executable command in a Ruby-like class you are able to start, define params and send signals (like kill, or stop)}
  gem.email = ['rgarcia@nosolosoftware.biz', 'lciudad@nosolosoftware.biz', 'pnavajas@nosolosoftware.biz', 'jaranda@nosolosoftware.biz']
  gem.authors = ['Rafael García', 'Luis Ciudad', 'Pedro Navajas', 'Javier Aranda']
  # dependencies defined in Gemfile

  # Files not included
  ['Gemfile', 'Rakefile', 'examples_helpers', 'features', 'spec'].each do |d|
    gem.files.exclude d
  end
end
Jeweler::RubygemsDotOrgTasks.new
