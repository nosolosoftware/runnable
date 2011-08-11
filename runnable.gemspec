# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{runnable}
  s.version = "0.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Rafael García}, %q{Luis Ciudad}, %q{Pedro Navajas}, %q{Javier Aranda}]
  s.date = %q{2011-08-11}
  s.description = %q{Convert a executable command in a Ruby-like class you are able to start, define params and send signals (like kill, or stop)}
  s.email = [%q{rgarcia@nosolosoftware.biz}, %q{lciudad@nosolosoftware.biz}, %q{pnavajas@nosolosoftware.biz}, %q{jaranda@nosolosoftware.biz}]
  s.extra_rdoc_files = [
    "README.markdown"
  ]
  s.files = [
    "COPYING",
    "README.markdown",
    "VERSION",
    "lib/runnable.rb",
    "lib/runnable/command_parser.rb",
    "lib/runnable/extended.rb",
    "lib/runnable/gnu.rb",
    "runnable.gemspec"
  ]
  s.homepage = %q{http://github.com/nosolosoftware/runnable}
  s.licenses = [%q{GPL-3}]
  s.require_paths = [%q{lib}]
  s.rubygems_version = %q{1.8.6}
  s.summary = %q{A Ruby gem for execute and control system commands}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, [">= 0.8.7"])
      s.add_development_dependency(%q<yard>, [">= 0.6.8"])
      s.add_development_dependency(%q<rspec>, [">= 2.5.0"])
      s.add_development_dependency(%q<cucumber>, [">= 0.10.2"])
      s.add_development_dependency(%q<jeweler>, [">= 1.6.0"])
      s.add_development_dependency(%q<bluecloth>, [">= 2.1.0"])
    else
      s.add_dependency(%q<rake>, [">= 0.8.7"])
      s.add_dependency(%q<yard>, [">= 0.6.8"])
      s.add_dependency(%q<rspec>, [">= 2.5.0"])
      s.add_dependency(%q<cucumber>, [">= 0.10.2"])
      s.add_dependency(%q<jeweler>, [">= 1.6.0"])
      s.add_dependency(%q<bluecloth>, [">= 2.1.0"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0.8.7"])
    s.add_dependency(%q<yard>, [">= 0.6.8"])
    s.add_dependency(%q<rspec>, [">= 2.5.0"])
    s.add_dependency(%q<cucumber>, [">= 0.10.2"])
    s.add_dependency(%q<jeweler>, [">= 1.6.0"])
    s.add_dependency(%q<bluecloth>, [">= 2.1.0"])
  end
end

