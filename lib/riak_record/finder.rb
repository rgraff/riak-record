module RiakRecord
  class Finder
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

    def each
      @loaded_objects.each{|o| yield o}
    end

    def count
      @load_complete ? @loaded_objects.count : count_by_map_reduce
    end

    def first(n=nil)
      if n
        until @load_complete || n <= @loaded_objects.count
          load_next_page
        end
        @loaded_objects.first(n)
      else
        load_next_page unless load_started?
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
      else
        load_next_page unless load_started?
        @loaded_objects.count.zero?
      end
    end
    alias :none? :empty?

    def any?(&block)
      if block_given?
        return true if @loaded_objects.any? &block
        until @load_complete
          load_next_page.any? &block
        end
        false
      else
        !empty?
      end
    end

  private

    def load_started?
      @load_complete || @loaded_objects.count > 0
    end

    def count_by_map_reduce
      Riak::MapReduce.new(@finder_class.client).
        index(@bucket, @index, @value).
        map("function(v){ return [1] }", :keep => false).
        reduce("Riak.reduceSum", :keep => true).run.first
    end

    def load_next_page
      return if @load_complete
      if @querier
        @querier = @querier.next_page
      else
        @querier = Riak::SecondaryIndex.new(@bucket, @index, @value, :max_results => @page_size)
      end
      @load_complete = !@querier.has_next_page?
      new_objects = @querier.values.map{ |robject| @finder_class.new(robject) }
      @loaded_objects.concat(new_objects)
      new_objects
    end

  end
end
