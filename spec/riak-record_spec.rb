require File.expand_path(File.dirname(__FILE__) + '/spec_helper')


class ExampleClient
end

RiakRecord.client = ExampleClient.new

class ExampleA < RiakRecord
  bucket_name 'example_a'
  record_attributes :attribute1, :attribute2
end

class ExampleB < RiakRecord
  bucket_name 'example_b'
end

describe "RiakRecord" do
  it "should set the bucket name on each instance of RiakRecord class" do
    expect(ExampleA.bucket_name).to eq('example_a')
    expect(ExampleB.bucket_name).to eq('example_b')
  end

  it "should share a client among all classes" do
    expect(ExampleA.client).to_not eq(nil)
    expect(ExampleA.client).to eq(ExampleB.client)
  end

  describe "find" do
    let(:bucket){ double }
    let(:array){ Array.new }
    before :each do
      allow(ExampleA).to receive(:bucket).and_return(bucket)
    end

    it "should take an array and return an array" do
      expect(bucket).to receive(:get_many).with(array).and_return([])
      ExampleA.find(array)
    end

    it "should take a string and return nil if not found" do
      allow(bucket).to receive(:get).with("a-key").and_return(nil)
      expect( ExampleA.find("a-key") ).to be_nil
    end

    it "should take a string and return an instance of Example" do
      allow(bucket).to receive(:get).with("a-key").and_return(double)
      expect( ExampleA.find("a-key") ).to be_an_instance_of(ExampleA)
    end
  end

  describe "record_attributes" do
    let(:riak_object) { double(:data => data) }
    let(:data) { {:attribute1 => "1"} }
    it "should respond to each attribute" do
      expect( ExampleA.new(riak_object) ).to respond_to(:attribute1)
      expect( ExampleA.new(riak_object) ).to respond_to(:attribute2)
    end

    it "should return attribute from riak_object data" do
      expect( ExampleA.new(riak_object).attribute1 ).to eq("1")
    end
  end
end
