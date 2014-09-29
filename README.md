# RiakRecord

RiakRecord is a thin and immature wrapper around riak-ruby-client. It creates a bucket for
each class, provides a simple finder, and creates attribute accessors for data and indexes.  It adds a layer over
the Riak::Client to make interacting with Riak more ActiveRecord-like while
still giving you all the access to Riak's underlying client's capabilities.

RiakRecord is is very similar to [Basho's Ripple](https://github.com/basho-labs/ripple) which is more feature rich
but also abandoned. For the [same reasons](http://basho.com/tag/ripple-client-apis/)
that Basho abandoned Ripple, you should think twice before using RiakRecord.

## Usage

```ruby
require 'riak_record'

RiakRecord::Base.client = Riak::Client.new
RiakRecord::Base.namespace = 'staging' # optional. Namespaces buckets

class Post < RiakRecord::Base
  bucket_name :posts
  data_attributes :title, :body

  index_int_attributes :author_id # author_id_int
  index_bin_attributes :category # catgory_bin
end

Post.client #> instance of Riak::Client
Post.bucket #> instance of Riak::Bucket named "staging:posts"

Post.find(["my-first-post","a-farewell-to-blogging"]) #> Array of Posts returned
post = Post.find("my-first-post") #> Instance of Post
post.riak_object #> directly access Riak::RObject
post.data #> same as record.riak_object.data

post.title = 'My First Post' #> record.riak_object.data['title']=
post.title #> record.riak_object.data['title']
post.update_attributes(:title => 'My First Post (revised)')

post.author_id = 99 #> record.riak_object.indexes["author_id_int"] = [99]
post.category = 'ruby' #> record.riak_object.indexes["category_bin"] = ["ruby"]
post.save  #> record.riak_object.store
post.new_record? #> false
post.reload #> reload the underlying riak_object from the db discarding changes

```

Callbacks are called in this order:
* before_save
* before_create or before_update
* ...save...
* after_create or after_update
* after_save


### RiakRecord::Finder

RiakRecord::Finder provides find objects by indexes. Results are loaded in batches as needed.

```ruby
finder = Post.where(:category => 'ruby') #> Instance of RiakRecord::Finder
finder.count #> 1
finder.any? #> true
finder.any?{|o| o.category == 'php'} #> false
finder.none? #> false
finder.each{|e| ... } #> supports all enumerable methods
finder.count_by(:author_id) #> {"1" => 1}
```

### RiakRecord::Associations

RiakRecord supports `has_many` and `belongs_to` associations which are light versions of what you'd expect with ActiveRecord.

```ruby
class Author < RiakRecord::Base
  bucket_name :authors
  data_attributes :name
  has_many :posts, :class_name => 'Post', :foreign_key => "post_id"
end

class Comment < RiakRecord::Base
  bucket_name :comments
  data_attribute :comment
  belongs_to :post, :class_name => 'Post', :foreign_key => "post_id"

  index_int_attributes :post_id
end

Author.find(99).posts #> RiakRecord::Finder [post]
Comment.find(12).author #> an instance of Author
```

### RiakRecord::Callbacks

RiakRecord supports before and after callbacks for save, create and update. You can prepend or append callbacks. And they can be strings (eval'd), Procs, Objects or Symbols.

```ruby
class Blog < RiakRecord::Base
  bucket :blogs
  data_attribute :subdomain

  class BlogCallbacks
    def before_update
    end
  end

  before_save Proc.new{|record| record.create_subdomain }
  after_create :send_welcome_email
  prepend_after_create "logger('new blog')"
  after_update :send_change_confirmation
  before_update BlogCallbacks.new

  ...
end

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
