# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: riak-record 0.7.0 ruby lib

Gem::Specification.new do |s|
  s.name = "riak-record"
  s.version = "0.7.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Robert Graff"]
  s.date = "2014-10-27"
  s.description = "RiakRecord is a thin and immature wrapper around riak-ruby-client. It creates a bucket for\n  each class, provides a simple finder, and creates attribute reader."
  s.email = "robert_graff@yahoo.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    ".document",
    ".rspec",
    "Gemfile",
    "Gemfile.lock",
    "Guardfile",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "TODO.md",
    "VERSION",
    "lib/riak_record.rb",
    "lib/riak_record/associations.rb",
    "lib/riak_record/base.rb",
    "lib/riak_record/callbacks.rb",
    "lib/riak_record/finder/basic.rb",
    "lib/riak_record/finder/erlang_enhanced.rb",
    "map_reduce/riak_record_kv_mapreduce.erl",
    "riak-record.gemspec",
    "spec/riak_record/associations_spec.rb",
    "spec/riak_record/base_spec.rb",
    "spec/riak_record/callbacks_spec.rb",
    "spec/riak_record/finder_spec.rb",
    "spec/riak_record_spec.rb",
    "spec/spec_helper.rb"
  ]
  s.homepage = "http://github.com/rgraff/riak-record"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.2.1"
  s.summary = "A wrapper around ruby-client."

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<riak-client>, ["~> 2.0.0"])
      s.add_development_dependency(%q<rspec>, ["~> 3.1.0"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 2.0.1"])
      s.add_development_dependency(%q<simplecov>, [">= 0"])
      s.add_development_dependency(%q<guard-rspec>, ["~> 4.3.1"])
      s.add_development_dependency(%q<guard-bundler>, [">= 0"])
      s.add_development_dependency(%q<terminal-notifier-guard>, [">= 0"])
    else
      s.add_dependency(%q<riak-client>, ["~> 2.0.0"])
      s.add_dependency(%q<rspec>, ["~> 3.1.0"])
      s.add_dependency(%q<rdoc>, ["~> 3.12"])
      s.add_dependency(%q<bundler>, ["~> 1.0"])
      s.add_dependency(%q<jeweler>, ["~> 2.0.1"])
      s.add_dependency(%q<simplecov>, [">= 0"])
      s.add_dependency(%q<guard-rspec>, ["~> 4.3.1"])
      s.add_dependency(%q<guard-bundler>, [">= 0"])
      s.add_dependency(%q<terminal-notifier-guard>, [">= 0"])
    end
  else
    s.add_dependency(%q<riak-client>, ["~> 2.0.0"])
    s.add_dependency(%q<rspec>, ["~> 3.1.0"])
    s.add_dependency(%q<rdoc>, ["~> 3.12"])
    s.add_dependency(%q<bundler>, ["~> 1.0"])
    s.add_dependency(%q<jeweler>, ["~> 2.0.1"])
    s.add_dependency(%q<simplecov>, [">= 0"])
    s.add_dependency(%q<guard-rspec>, ["~> 4.3.1"])
    s.add_dependency(%q<guard-bundler>, [">= 0"])
    s.add_dependency(%q<terminal-notifier-guard>, [">= 0"])
  end
end

