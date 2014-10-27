%% @doc Riak Record's map/reduce phases
-module(riak_record_kv_mapreduce).

-export([map_count_found/3,
         map_pluck_value/3,
         map_pluck_index/3,
         map_count_by_value/3,
         map_count_by_index/3,
         reduce_count_by/2]).



%% @doc map phase function that returns the count of objects.
map_count_found({error, notfound}, _, _) ->
  [0];
map_count_found(_, _, _) ->
  [1].

%% @doc map phase function plucks value specified by Arg from the
%% JSON encoded RiakObject's value.
map_pluck_value({error, notfound}, _, _) ->
  [];
map_pluck_value(RiakObject, _Props, Arg) ->
  RiakValue = riak_object:get_value(RiakObject),
  {struct, JsonData} = mochijson2:decode(RiakValue),
  Value = proplists:get_value(list_to_binary(Arg), JsonData),
  [Value].

%% @doc map phase function plucks values from the indexes speicied
%% by Arg from the RiakObject's metadata.
map_pluck_index({error, notfound}, _, _) ->
  [];
map_pluck_index(RiakObject, _Props, Arg) ->
  Meta = riak_object:get_metadata(RiakObject),
  Indexes = dict:fetch(<<"index">>, Meta),
  proplists:get_all_values(list_to_binary(Arg), Indexes).


%% dry it up!
map_count_by_value({error, notfound}, _, _) ->
  [{struct, []}];
map_count_by_value(RiakObject, _Props, Arg) ->
  RiakValue = riak_object:get_value(RiakObject),
  {struct, JsonData} = mochijson2:decode(RiakValue),
  Value = proplists:get_value(list_to_binary(Arg), JsonData),
  [{struct, [{Value,1}]}].

map_count_by_index({error, notfound}, _, _) ->
  [{struct, []}];
map_count_by_index(RiakObject, _Props, Arg) ->
  Meta = riak_object:get_metadata(RiakObject),
  Indexes = dict:fetch(<<"index">>, Meta),
  IndexValues = proplists:get_all_values(list_to_binary(Arg), Indexes),
  ToTuple = fun(V) -> {V, 1} end,
  [{struct, lists:map(ToTuple, IndexValues)}].

reduce_count_by(Values, _Arg) ->
  Sum = fun(_,V1,V2) -> V1 + V2 end,
  Merge = fun(D1,D2) -> orddict:merge(Sum,D1,D2) end,
  ToList = fun(X) -> {struct, L} = X, L end,
  Lists = lists:map(ToList, Values),
  List = lists:foldl(Merge, [], Lists),
  [{struct, List}].
