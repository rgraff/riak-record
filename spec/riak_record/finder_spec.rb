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

  describe "all" do

    it "should return all the records that match the conditions" do
      expect( pop_finder.all.map(&:id).sort ).to eq(@pop_artists.map(&:id).sort)
    end

    it "should not return all the record that do not match the conditions" do
      expect( pop_finder.all.map(&:id) ).to_not include(@rock_artists.map(&:id))
    end

  end
end
