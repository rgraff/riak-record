class RiakRecord
  VERSION = "0.0.0.1"

  attr_reader :riak_object

  def initialize(riak_object)
    @riak_object = riak_object
  end

  def data
    riak_object.data
  end

  def self.bucket_name(name = :not_a_name)
    @bucket_name = name unless name == :not_a_name
    @bucket_name
  end

  def self.bucket
    @bucket ||= riak_client.bucket(@bucket_name)
  end

  def self.record_attributes(*attributes)
    attributes.each do |method_name|
      send :define_method, method_name do
          data[method_name]
      end
    end
  end


  def self.find(key_or_keys)
    if key_or_keys.is_a?(Array)
      bucket.get_many(key_or_keys).map{ |r| self.new(r) }
    else
      r = bucket.get(key_or_keys)
      self.new(r) unless r.nil?
    end
  end

  def self.client=(client)
    @@client = client
  end

  def self.client
    @@client
  end

end
