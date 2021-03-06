module RiakRecord
module Finder
  class Basic
    include Enumerable

    def initialize(finder_class, conditions)
      unless finder_class <= RiakRecord::Base
        raise ArgumentError, "RiakRecord::Finder requires a RiakRecord::Base class"
      end
      unless conditions.is_a?(Hash) && conditions.size == 1
        raise ArgumentError, "RiakRecord::Finder requires exactly one condition specified as a hash"
      end
      @finder_class = finder_class
      @bucket = finder_class.bucket
      @index = finder_class.index_names[conditions.keys.first.to_sym]
      @value = conditions.values.first
      @load_complete = false
      @page_size = 100
      @loaded_objects = []
    end

    def all
      until @load_complete do
        load_next_page
      end
      @loaded_objects
    end
    alias :to_ary :all # internal array

    def to_a
      all.dup # new array
    end

    def keys
      @keys ||= Riak::SecondaryIndex.new(@bucket, @index, @value).keys
    end

    def each
      all.each{|o| yield o}
    end

    def count
      @load_complete ? @loaded_objects.count : count_map_reduce
    end

    def first(n=nil)
      if n
        unless @load_complete || @loaded_objects.count >= n
          load_next_page(n-@loaded_objects.count)
        end
        @loaded_objects.first(n)
      else
        load_next_page(1) unless load_started?
        @loaded_objects.first
      end
    end

    def find(ifnone = nil, &block)
      found = @loaded_objects.find(&block)
      until found || @load_complete
        found = load_next_page.find(&block)
      end
      return found if found
      return ifnone.call if ifnone
      nil
    end
    alias :detect :find

    def empty?(&block)
      if block_given?
        !any?(&block)
      elsif load_started?
        @loaded_objects.count.zero?
      else
        Riak::SecondaryIndex.new(@bucket, @index, @value, :max_results => 1).keys.empty?
      end
    end
    alias :none? :empty?

    def any?(&block)
      if block_given?
        return true if @loaded_objects.any? &block
        until @load_complete
          return true if load_next_page.any? &block
        end
        false
      else
        !empty?
      end
    end

    def count_by(attribute)
      return count_by_map_reduce(attribute) unless @load_complete
      results = {}
      @loaded_objects.each{|o| k = o.send(attribute).to_s; results[k] ||= 0; results[k] += 1 }
      results
    end

    def page(continuation = nil, page_size = 100)
      options = { :max_results => page_size }
      options[:continuation] = continuation if continuation.present?
      querier = Riak::SecondaryIndex.new(@bucket, @index, @value, options)
      results = querier.values.compact.map{ |robject| @finder_class.new(robject) }
      return results, querier.keys.continuation
    end

    def pluck_by_map_reduce(attribute, timeout = nil)
      pluck_by_index = @finder_class.index_names[attribute.to_sym].present?
      parsed_attribute = pluck_by_index ? "v.values[0].metadata.index.#{@finder_class.index_names[attribute.to_sym]}" : "JSON.parse(v.values[0].data).#{attribute}"
      mr = new_map_reduce.map("function(v){ return [#{parsed_attribute}] }", :keep => true)
      mr.timeout = timeout if timeout.present?
      mr.run
    end

    def count_by_map_reduce(attribute, timeout = nil)
      count_by_index = @finder_class.index_names[attribute.to_sym].present?
      parsed_attribute = count_by_index ? "v.values[0].metadata.index.#{@finder_class.index_names[attribute.to_sym]}" : "JSON.parse(v.values[0].data).#{attribute}"
      mr = new_map_reduce.map("function(v){ var h = {}; h[#{parsed_attribute}] = 1; return [h] }", :keep => false).
        reduce("function(values) { var result = {}; for (var value in values) { for (var key in values[value]) { if (key in result) { result[key] += values[value][key]; } else { result[key] = values[value][key]; }}} return [result]; }", :keep => true)
      mr.timeout = timeout if timeout.present?
      mr.run.first
    end

    def count_map_reduce(timeout = nil)
      mr = new_map_reduce.map("function(v){ return [1] }", :keep => false).
        reduce(['riak_kv_mapreduce','reduce_sum'], :keep => true)
      mr.timeout = timeout if timeout.present?
      mr.run.first
    end


  private

    def new_map_reduce
      Riak::MapReduce.new(@finder_class.client).index(@bucket, @index, @value)
    end

    def load_started?
      @load_complete || @loaded_objects.count > 0
    end

    def load_next_page(page_size = @page_size)
      return if @load_complete
      if @querier
        @querier = @querier.next_page
      else
        @querier = Riak::SecondaryIndex.new(@bucket, @index, @value, :max_results => page_size)
      end
      @load_complete = !@querier.has_next_page?
      new_objects = @querier.values.compact.map{ |robject| @finder_class.new(robject) }
      @loaded_objects.concat(new_objects)
      new_objects
    end

  end
end
end
