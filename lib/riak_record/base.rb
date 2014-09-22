require 'riak'

module RiakRecord
  class Base
    attr_reader :riak_object

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
      riak_object.store(:returnbody => false)
      self
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

    def self.belongs_to(attribute, options = {})
      class_name = options[:class_name] ||= attribute.to_s.to_s.split("_").collect(&:capitalize).join
      key = options[:key] || "#{attribute}_id"
      method_def = <<-END_OF_RUBY

      def #{attribute}
        @belongs_to_#{attribute} = nil if @belongs_to_#{attribute} && @belongs_to_#{attribute}.id == #{key}
        @belongs_to_#{attribute} ||= #{class_name}.find(#{key})
      end

      def #{attribute}=(obj)
        raise ArgumentError unless obj.kind_of?(RiakRecord::Base)
        @belongs_to_#{attribute} = obj
        self.#{key} = obj.id
      end
      END_OF_RUBY

      class_eval method_def
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
      self.namespace + ":-:"
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
