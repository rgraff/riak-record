require 'riak'

module RiakRecord
  class Base
    attr_reader :riak_object

    def initialize(r = nil)
      r = self.class.bucket.new(r) if r.nil? || r.is_a?(String)
      raise ArgumentError unless r.is_a? Riak::RObject
      @riak_object = r
    end

    def data
      riak_object.data
    end

    def save
      riak_object.store(:returnbody => false)
    end

    def self.bucket_name(name = :not_a_name)
      @bucket_name = name unless name == :not_a_name
      namespace.present? ? namespace+":-:"+@bucket_name : @bucket_name
    end

    def self.bucket
      @bucket ||= client.bucket(bucket_name)
    end

    def self.record_attributes(*attributes)
      attributes.each do |method_name|
        define_method(method_name) do
            data[method_name]
        end

        define_method("#{method_name}=".to_sym) do |value|
          data[method_name] = value
        end
      end
    end

    def self.find(key_or_keys)
      return find_many(key_or_keys) if key_or_keys.is_a?(Array)

      begin
        self.new(bucket.get(key_or_keys.to_s))
      rescue Riak::FailedRequest => e
        if e.not_found?
          nil
        else
          raise e
        end
      end
    end

    def self.find_many(keys)
      hash = bucket.get_many(keys.map(&:to_s))
      keys.map{ |k| hash[k] }
    end

    @@namespace = nil
    def self.namespace=(namespace)
      @@namespace = namespace
    end

    def self.namespace
      @@namespace
    end

    def self.client=(client)
      @@client = client
    end

    def self.client
      @@client
    end

  end
end
