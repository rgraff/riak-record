module RiakRecord
  class Finder::ErlangEnhanced < Finder::Basic

    def pluck_by_map_reduce(attribute, timeout = nil)
      map_method, map_arg = map_method_for_attribute(attribute, "map_pluck_index", "map_pluck_value")
      mr = Riak::MapReduce.new(@finder_class.client).
        index(@bucket, @index, @value).
        map(['riak_record_kv_mapreduce', map_method], :keep => true, :arg => [map_arg])
      mr.timeout = timeout if timeout.present?
      mr.run
    end

    def count_by_map_reduce(attribute, timeout = nil)
      map_method, map_arg = map_method_for_attribute(attribute, "map_count_by_index", "map_count_by_value")
      mr = Riak::MapReduce.new(@finder_class.client).
        index(@bucket, @index, @value).
        map(['riak_record_kv_mapreduce', map_method], :keep => false, :arg => [map_arg]).
        reduce(['riak_record_kv_mapreduce', 'reduce_count_by'], :keep => true)
      mr.timeout = timeout if timeout.present?
      mr.run.first
    end

    def count_map_reduce(timeout = nil)
      mr = Riak::MapReduce.new(@finder_class.client).
        index(@bucket, @index, @value).
        map(['riak_record_kv_mapreduce', 'map_count_found'], :keep => false).
        reduce(['riak_kv_mapreduce','reduce_sum'], :keep => true)
      mr.timeout = timeout if timeout.present?
      mr.run.first
    end


  private

    def map_method_for_attribute(attribute, index_method, value_method)
      count_by_index = @finder_class.index_names[attribute.to_sym].present?
      map_method = count_by_index ? index_method : value_method
      map_arg = count_by_index ? @finder_class.index_names[attribute.to_sym] : attribute
      [map_method, map_arg]
    end

  end

end
