require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class Author < RiakRecord::Base
  bucket_name "authors"
  data_attributes :name
end

class Post #< ActiveRecord
  include RiakRecord::Associations

  belongs_to_riak :author, :class_name => 'Author', :foreign_key => :author_id
  has_many_riak :comments, :class_name => 'Comment', :foreign_key => :post_id

  def id
    1
  end

  def author_id
    @author_id ||= "12"
  end

  def author_id=(v)
    @author_id = v
  end

end

class Comment < RiakRecord::Base
  bucket_name "comments"
  data_attributes :comment

  index_int_attributes :post_id
end

describe RiakRecord::Associations do
  let(:post){ post = Post.new }

  describe "belongs_to_riak" do
    before :each do
      @author = Author.new("12")
      @author.name = 'Dr.Seuss'
      @author.save

      @real_author = Author.new("13")
      @real_author.name = 'T. Geisel'
      @real_author.save
    end

    it "should return the riak object" do
      expect(post.author.name).to eq(@author.name)
    end

    it "should change the results when you change the foreign key value" do
      expect{
        post.author_id = @real_author.id
      }.to change{ post.author.name }.from(@author.name).to(@real_author.name)
    end

    it "should set the foreign_key" do
      expect{
        post.author = @real_author
      }.to change{ post.author_id }.from(@author.id).to(@real_author.id)
    end

  end

  describe "has_many_riak" do
    before :each do
      @comment = Comment.new("1")
      @comment.comment = "first!"
      @comment.post_id = post.id
      @comment.save

      @other_comment = Comment.new("2")
      @other_comment.comment = "+2"
      @other_comment.post_id = post.id
      @other_comment.save

      @comment_for_other_post = Comment.new("3")
      @comment_for_other_post.comment = "first!"
      @comment_for_other_post.post_id = post.id + 1
      @comment_for_other_post.save
    end
    it "should return a RiakRecord::Finder" do
      expect(post.comments).to be_an_instance_of(RiakRecord::Finder)
    end

    it "should include the associated records" do
      expect(post.comments.all.map(&:id)).to include(@comment.id, @other_comment.id)
      expect(post.comments.all.map(&:id)).to_not include(@comment_for_other_post.id)
    end
  end
end
