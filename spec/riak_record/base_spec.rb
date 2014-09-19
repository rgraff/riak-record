require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class ExampleA < RiakRecord::Base
  bucket_name 'example_a'
  data_attributes :attribute1, :attribute2
  index_int_attributes :index1, :index2
  index_bin_attributes :index3, :index4
end

class ExampleB < RiakRecord::Base
  bucket_name :example_b
end

describe RiakRecord::Base do
  it "should set the bucket name on each instance of RiakRecord class" do
    expect(ExampleA.bucket_name).to eq('example_a')
    expect(ExampleB.bucket_name).to eq('example_b')
  end

  it "should share a client among all classes" do
    expect(ExampleA.client).to_not eq(nil)
    expect(ExampleA.client).to eq(ExampleB.client)
  end

  describe "new" do
    context "when passed in an RObject" do
      let(:robject) { Riak::RObject.new("a-key") }
      let(:record) { ExampleA.new(robject) }
      it "should wrap it" do
        expect(record.riak_object).to eq(robject)
        expect(record).to be_a(ExampleA)
      end
    end
    context "when passed in a string" do
      let(:key) { 'judy' }
      let(:record) { ExampleA.new(key) }
      it "should create an RObject with that id" do
        expect(record).to be_a(ExampleA)
        expect(record.riak_object).to be_a(Riak::RObject)
        expect(record.riak_object.key).to eq(key)
      end
    end
    context "when passed in nil" do
      let(:record) { ExampleA.new() }
      it "should create an RObject with no id" do
        expect(record).to be_a(ExampleA)
        expect(record.riak_object).to be_a(Riak::RObject)
      end
    end
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
      e = Riak::FailedRequest.new("not found")
      allow(e).to receive(:not_found?).and_return(true)
      allow(bucket).to receive(:get).with("a-key").and_raise(e)
      expect( ExampleA.find("a-key") ).to be_nil
    end

    it "should take a string and return an instance of Example" do
      allow(bucket).to receive(:get).with("a-key").and_return(Riak::RObject.new("a-key"))
      expect( ExampleA.find("a-key") ).to be_an_instance_of(ExampleA)
    end
  end

  describe "data_attributes" do
    let(:riak_object) { Riak::RObject.new("obj").tap{|r| r.data = data } }
    let(:data) { {:attribute1 => "1"} }
    let(:record) { ExampleA.new(riak_object) }
    it "should read and write each attribute" do
      expect{
        record.attribute1=('b')
      }.to change{record.attribute1}.from("1").to('b')

      expect{
        record.attribute2 = 'c'
      }.to change{record.attribute2}.from(nil).to('c')

    end

    it "should return attribute from riak_object data" do
      expect( ExampleA.new(riak_object).attribute1 ).to eq("1")
    end

  end

  describe "index_int_attributes" do
    let(:riak_object) { Riak::RObject.new("obj").tap{|r| r.indexes["index1_int"] = [1] } }
    let(:record) { ExampleA.new(riak_object) }
    it "should read and write each index" do
      expect{
        record.index1=[2]
      }.to change{record.riak_object.indexes["index1_int"]}.from([1]).to([2])
    end

    it "should handle non arrays" do
      expect{
        record.index2=2
      }.to change{record.index2}.from([]).to([2])
    end

    it "should handle nil" do
      expect{
        record.index1 = nil
      }.to change{record.index1}.from([1]).to([])
    end
  end

  describe "index_bin_attributes" do
    let(:riak_object) { Riak::RObject.new("obj").tap{|r| r.indexes["index3_bin"] = ['apple'] } }
    let(:record) { ExampleA.new(riak_object) }
    it "should read and write each index" do
      expect{
        record.index3=['mac']
      }.to change{record.riak_object.indexes["index3_bin"]}.from(['apple']).to(['mac'])
    end

    it "should handle non arrays" do
      expect{
        record.index4='mac'
      }.to change{record.index4}.from([]).to(['mac'])
    end

    it "should handle nil" do
      expect{
        record.index3 = nil
      }.to change{record.index3}.from(['apple']).to([])
    end
  end

  describe "namespacing buckets" do
    it "should prepend namespace to bucket name" do
      RiakRecord::Base.namespace = "namespace_test"
      expect(ExampleA.bucket_name).to eq("namespace_test:-:example_a")
    end
  end
end
