# riak-record

RiakRecord is a thin and immature wrapper around riak-ruby-client. It creates a bucket for
each class, provides a simple finder, and creates attribute reader.  It adds a layer over
the Riak::Client to make interacting with Riak more ActiveRecord-like while
still giving you all the access to Riak's underlying client's capabilities.

## Usage

```ruby
require 'riak-record'

RiakRecord::Base.client = Riak::Client.new
RiakRecord::Base.namespace = 'staging' # optional. Namespaces buckets

class Post < RiakRecord::Base
  bucket_name :posts
  data_attributes :title, :body, :category
  belongs_to :author
  has_many :comments

  index_int_attributes :author_id # author_id_int
  index_bin_attributes :category # catgory_bin
end

class Author < RiakRecord::Base
  bucket_name :authors
  data_attributes :name
  has_many :posts
end

class Comment < RiakRecord::Base
  bucket_name :comments
  data_attribute :comment
  belongs_to :post

  index_int_attributes :post_id
end

Author.client #> instance of Riak::Client
Author.bucket #> instance of Riak::Bucket

author = Author.new(99) # create a new record with id/key 99
author.name = 'Robert' # set an attribute
author.save # store in riak

Post.find(["my-first-post","a-farewell-to-blogging"]) #> Array of ExampleRecords returned

post = Post.find("my-first-post") #> Instance of ExampleRecord
post.riak_object #> directly access Riak::RObject
post.data #> same as record.riak_object.data

post.title = 'My First Post' #> record.riak_object.data['title']=
post.title #> record.riak_object.data['title']

post.author = 99 #> record.riak_object.indexes["author_id_int"] = [99]
post.category = 'ruby' #> record.riak_object.indexes["category_bin"] = ["ruby"]
post.save  #> record.riak_object.store
post.reload #> reload the underlying riak_object from the db discarding changes

Author.find(99).posts #> [post]

finder = Post.where(:category => 'ruby') #> Instance of RiakRecord::Finder
finder.count #> 1
finder.any? #> true
finder.any?{|o| o.category == 'php'} #> false
finder.none? #> false
finder.each{|e| ... } #> supports all enumerable methods
finder.count_by(:author_id) #> {"1" => 1}
```

## Using RiakRecord::Associations in other classes

If you're using another data store with Riak, it might be helpful to include Riak's associations in the other class.

```ruby
class User < ActiveRecord::Base
  include RiakRecord::Assocations

  has_many_riak :posts, :class_name => "Post", :foreign_key => :user_id
  belongs_to_riak :author, :class_name => "Author", :foreign_key => :author_id
end

User.find(1).posts #> create RiakRecord::Finder(Post, :user_id => 1)
User.find(1).author #> Author.find(self.author_id)
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
