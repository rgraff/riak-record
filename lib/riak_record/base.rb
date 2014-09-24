require 'riak'

module RiakRecord
  class Base
    attr_reader :riak_object
    include Callbacks
    include Associations
    class << self
      alias :has_many :has_many_riak
      alias :belongs_to :belongs_to_riak
    end

    def initialize(r = nil)
      unless r.is_a? Riak::RObject
        r = self.class.bucket.new(r.to_s)
        r.data = {}
      end
      @riak_object = r
    end

    def data
      riak_object.data
    end

    def indexes
      riak_object.indexes
    end

    def save
      creating = new_record?

      before_save!
      creating ? before_create! : before_update!
      riak_object.store(:returnbody => false)
      creating ? after_create! : after_update!
      after_save!

      @_stored = true
      self
    end

    def new_record?
      !(@_stored || riak_object.vclock)
    end

    def id
      riak_object.key
    end

    def reload
      @riak_object = self.class.bucket.get(id)
      @riak_object.data = {} if @riak_object.data.nil?
      self
    end

    def self.bucket_name(name = :not_a_name)
      @bucket_name = name.to_s unless name == :not_a_name
      namespace.present? ? namespace_prefixed+@bucket_name : @bucket_name
    end

    def self.bucket
      @bucket ||= client.bucket(bucket_name)
    end

    def self.data_attributes(*attributes)
      attributes.map(&:to_sym).each do |method_name|
        define_method(method_name) do
            data[method_name.to_s]
        end

        define_method("#{method_name}=".to_sym) do |value|
          data[method_name.to_s] = value
        end
      end
    end

    def self.index_int_attributes(*attributes)
      attributes.map(&:to_sym).each do |method_name|
        index_names[method_name.to_sym] = "#{method_name}_int"

        define_method(method_name) do
          indexes["#{method_name}_int"]
        end

        define_method("#{method_name}=".to_sym) do |value|
          indexes["#{method_name}_int"] = Array(value).map(&:to_i)
        end
      end
    end

    def self.index_bin_attributes(*attributes)
      attributes.map(&:to_sym).each do |method_name|
        index_names[method_name.to_sym] = "#{method_name}_bin"

        define_method(method_name) do
          indexes["#{method_name}_bin"]
        end

        define_method("#{method_name}=".to_sym) do |value|
          indexes["#{method_name}_bin"] = Array(value).map(&:to_s)
        end
      end
    end

    def self.index_names
      @index_names ||= {}
    end

    def self.where(options)
      RiakRecord::Finder.new(self, options)
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

    def self.namespace_prefixed
      self.namespace + ":"
    end

    def self.all_buckets_in_namespace
      raise "namespace not set" unless self.namespace
      client.list_buckets.select{|b| b.name.match(/^#{ Regexp.escape(self.namespace_prefixed) }/) }
    end

    def self.client=(client)
      @@client = client
    end

    def self.client
      @@client
    end

  end
end
