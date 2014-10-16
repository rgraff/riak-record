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

    def initialize(options = nil)
      if options.is_a?(Riak::RObject)
        @riak_object = options
      else
        @riak_object = self.class.bucket.new
        @riak_object.content_type = 'application/json'
        @riak_object.data = {}
        if options.is_a?(Hash)
          id = options.delete(:id) || options.delete(:key)
          @riak_object.key = id.to_s if id
          options.each_pair{ |k,v| self.send("#{k}=".to_sym, v) }
        elsif !options.nil?
          @riak_object.key = options.to_s
        end
      end
    end

    def data
      riak_object.data
    end

    def indexes
      riak_object.indexes
    end

    def links
      riak_object.links
    end

    def save
      creating = new_record?

      before_save!
      creating ? before_create! : before_update!

      update_links
      riak_object.store(:returnbody => false)

      creating ? after_create! : after_update!
      after_save!

      @_stored = true
      self
    end
    alias :save! :save

    def self.create(*args)
      self.new(*args).save
    end

    def self.create!(*args)
      self.new(*args).save
    end

    def delete
      riak_object.delete
    end

    def new_record?
      !(@_stored || riak_object.vclock)
    end

    def id
      riak_object.key
    end

    def to_param
      id
    end

    def ==(record)
      return false unless record.kind_of?(RiakRecord::Base)
      self.class.bucket_name == record.class.bucket_name && id == record.id
    end

    def reload
      @riak_object = self.class.bucket.get(id)
      @riak_object.data = {} if @riak_object.data.nil?
      self
    end

    def update_attributes(attributes)
      attributes.each_pair do |k,v|
        setter = "#{k}=".to_sym
        self.send(setter, v) if respond_to?(setter)
      end
      save
    end

    def self.bucket_name(name = :not_a_name)
      @bucket_name = name.to_s unless name == :not_a_name
      namespace.present? ? namespace_prefixed+@bucket_name : @bucket_name
    end

    def self.bucket
      @bucket ||= client.bucket(bucket_name)
    end

    def self.finder
      RiakRecord::Finder.new(self, :bucket => bucket_name)
    end

    def self.all
      finder.all
    end

    def self.count
      finder.count
    end

    def self.first(n = 1)
      finder.first(n)
    end

    def self.page(page_number = 1, page_size = 100)
      finder.page(page_number, page_size)
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
          indexes["#{method_name}_int"].to_a
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
          indexes["#{method_name}_bin"].to_a
        end

        define_method("#{method_name}=".to_sym) do |value|
          indexes["#{method_name}_bin"] = Array(value).map(&:to_s)
        end
      end
    end

    def self.index_names
      @index_names ||= { :bucket => '$bucket' }
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
      values = keys.map{ |k| hash[k] }.compact
      values.map{|robject| new(robject) }
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
