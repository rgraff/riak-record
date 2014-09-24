require 'simplecov'

module SimpleCov::Configuration
  def cleans
    @filters = []
  end
end

SimpleCov.configure do
  cleans
  load_profile 'test_frameworks'
end

ENV["COVERAGE"] && SimpleCov.start do
  add "/.rvm/"
end
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec'
require 'riak_record'

RiakRecord::Base.client = Riak::Client.new(:host => 'localhost', :pb_port => '8087')
Riak.disable_list_keys_warnings = true

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.before do
    RiakRecord::Base.namespace = 'test'
    RiakRecord::Base.all_buckets_in_namespace.each do |bucket|
      bucket.keys.each{|k| bucket.delete(k) }
    end
  end
end
