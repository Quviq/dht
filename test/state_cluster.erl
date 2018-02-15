-module(state_cluster).

-include_lib("eqc/include/eqc.hrl").
-include_lib("eqc/include/eqc_cluster.hrl").

-include("dht_eqc.hrl").

-compile(export_all).
-define(DRIVER, dht_routing_tracker).

components() -> [
	dht_state_eqc,
	dht_routing_meta_eqc,
	dht_routing_table_eqc,
	dht_time_eqc
].

api_spec() -> eqc_cluster:api_spec(?MODULE).

prop_cluster_correct() ->
    ?SETUP(fun() ->
        eqc_mocking:start_mocking(api_spec(), components()),
        fun() -> ok end
    end,
    ?FORALL(ID, dht_eqc:id(),
    ?FORALL({MetaState, TableState, State},
            {dht_routing_meta_eqc:gen_state(ID),
             dht_routing_table_eqc:gen_state(ID),
             dht_state_eqc:gen_state(ID)},
    ?FORALL(Cmds, eqc_cluster:commands(?MODULE, [
    		{dht_state_eqc, State},
    		{dht_routing_meta_eqc, MetaState},
    		{dht_routing_table_eqc, TableState}]),
      begin
        ok = dht_state_eqc:reset(),
        ok = routing_table:reset(ID, ?ID_MIN, ?ID_MAX),
        {H,S,R} = run_commands(?MODULE, Cmds),
        pretty_commands(?MODULE, Cmds, {H,S,R},
            aggregate(with_title('Commands'), command_names(Cmds),
            collect(eqc_lib:summary('Length'), length(Cmds),
            collect(eqc_lib:summary('Routing Table Size'), rt_size(S),
            aggregate(with_title('Features'), eqc_statem:call_features(H),
            features(eqc_statem:call_features(H),
                R == ok))))))
      end)))).
    
rt_size(Components) ->
    V = proplists:get_value(dht_routing_table_eqc, Components),
    length(dht_routing_table_eqc:current_nodes(V)).

t() -> t(15).

t(Secs) ->
    eqc:quickcheck(eqc:testing_time(Secs, eqc_statem:show_states(prop_cluster_correct()))).

recheck() ->
    eqc:recheck(eqc_statem:show_states(prop_cluster_correct())).

cmds() ->
    ?LET(ID, dht_eqc:id(),
    ?LET({MetaState, TableState, State},
            {dht_routing_meta_eqc:gen_state(ID),
             dht_routing_table_eqc:gen_state(ID),
             dht_state_eqc:gen_state(ID)},
    eqc_cluster:commands(?MODULE, [
    		{dht_state_eqc, State},
    		{dht_routing_meta_eqc, MetaState},
    		{dht_routing_table_eqc, TableState}]))).
    		
sample() ->
    eqc_gen:sample(cmds()).
   