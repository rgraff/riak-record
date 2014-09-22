require 'pry'
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class Artist < RiakRecord::Base
  bucket_name 'artist'
  data_attributes :name
  index_int_attributes :sales
  index_bin_attributes :category
end

describe RiakRecord::Finder do
  before :each do
    @pop_artists = Array(1..155).map do |c|
      a = Artist.new(c.to_s)
      a.name = "Pop Artist #{c}"
      a.category = "pop"
      a.save
    end

    @rock_artists = Array(156..203).map do |c|
      a = Artist.new(c.to_s)
      a.name = "Rock Artist #{c}"
      a.category = "rock"
      a.save
    end
  end

  let(:pop_finder){ RiakRecord::Finder.new(Artist, :category => 'pop') }
  let(:country_finder){ RiakRecord::Finder.new(Artist, :category => 'country') }

  describe "all" do

    it "should return all the records that match the conditions" do
      expect( pop_finder.all.map(&:id).sort ).to eq(@pop_artists.map(&:id).sort)
    end

    it "should not return all the record that do not match the conditions" do
      expect( pop_finder.all.map(&:id) ).to_not include(@rock_artists.map(&:id))
    end

  end

  describe "count" do
    it "should return the count by map reduce" do
      expect(pop_finder).to receive(:count_by_map_reduce).and_call_original
      expect(pop_finder.count).to eq(155)
    end

    context "all results in memory" do
      before :each do
        pop_finder.all # load complete
      end

      it "should not count by map reduce if load complete" do
        expect(pop_finder).to_not receive(:count_by_map_reduce)
        expect(pop_finder.count).to eq(155)
      end
    end
  end

  describe "enumberable methods" do
    it "should yield once per block" do
      expect( pop_finder.all?{|o| o.category == 'rock'} ).to eq(true)
    end
  end

  describe "any?" do
    it "should return true if there are any" do
      expect(pop_finder.any?).to eq(true)
    end
    it "should return false if there aren't any" do
      expect(country_finder.any?).to eq(false)
    end
    it "should handle a block" do
      expect(pop_finder.any?{|o| o.id == "none"}).to eq(false)
      expect(pop_finder.any?{|o| o.id == @pop_artists.last.id}).to eq(true)
    end
  end

  describe "empty? / none" do
    it "should return true if there aren't any" do
      expect(pop_finder.empty?).to eq(false)
    end
    it "should return false if there are any" do
      expect(country_finder.empty?).to eq(true)
    end
    it "should return true if there aren't any" do
      expect(pop_finder.none?).to eq(false)
    end
    it "should return false if there are any" do
      expect(country_finder.none?).to eq(true)
    end
    it "should handle a block" do
      expect(pop_finder.none?{|o| o.id == 'none'}).to eq(true)
      expect(pop_finder.none?{|o| o.id == @pop_artists.last.id}).to eq(false)
    end
  end

  describe "first" do
    it "should return something if not empty" do
      expect(pop_finder.first).to_not be_nil
    end
    it "should return nil if empty" do
      expect(country_finder.first).to be_nil
    end
    it "should handle a quantity" do
      expect(pop_finder.first(71).count).to eq(71)
    end
  end

  describe "find" do
    it "should return the first object to match block" do
      expect(pop_finder.find{|o| o.id =~ /^4/}.id).to match(/^4/)
    end
  end

  describe "detect" do
    it "should return the first object to match block" do
      expect(pop_finder.detect{|o| o.id =~ /^3/}.id).to match(/^3/)
    end
  end

end
