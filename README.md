# riak-record

RiakRecord is a thin and immature wrapper around riak-ruby-client. It creates a bucket for
each class, provides a simple finder, and creates attribute reader.

## Usage

```ruby
require 'riak-record'

RiakRecord.client = Riak::Client.new
RiakRecord.namespace = 'staging' # optional. Namespaces buckets

class ExampleRecord < RiakRecord
  bucket_name 'example_a'
  record_attributes :attribute1, :attribute2
end

ExampleRecord.find("a-key") #> Instance of ExampleRecord
ExampleRecord.find(["a-key","b-key"]) #> Array of ExampleRecords returned

record = ExampleRecord.find("a-key")
record.riak_object #> directly access Riak::RObject
record.data #> same as record.riak_object.data
record.attribute1 #> record.riak_object.data[:attribute1]
record.attribute1 = 'name'
record.save  #> record.riak_object.store
```



## Contributing to riak-record

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2014 Robert Graff. See LICENSE.txt for
further details.
