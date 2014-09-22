module RiakRecord
  class Finder
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

  private

    def load_next_page
      return if @load_complete
      if @querier
        @querier = @querier.next_page
      else
        @querier = Riak::SecondaryIndex.new(@bucket, @index, @value, :max_results => @page_size)
      end
      new_objects = @querier.values.map{ |robject| @finder_class.new(robject) }
      @loaded_objects.concat(new_objects)
      @load_complete = !@querier.has_next_page?
    end

  end
end
