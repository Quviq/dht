-module(net_cluster).

-include_lib("eqc/include/eqc.hrl").
-include_lib("eqc/include/eqc_cluster.hrl").

-include("dht_eqc.hrl").

-compile(export_all).

components() -> [
	dht_net_eqc,
	dht_store_eqc,
	dht_time_eqc
].

api_spec() -> eqc_cluster:api_spec(?MODULE).

prop_cluster_correct() ->
    ?SETUP(fun() ->
        application:load(dht),
        eqc_mocking:start_mocking(api_spec(), components()),
        fun() -> ok end
    end,
    ?FORALL(Cmds,
          fault_rate(1,40, eqc_cluster:commands(?MODULE)),
      begin
        ok = dht_net_eqc:reset(),
        {H,S,R} = run_commands(?MODULE, Cmds),
        pretty_commands(?MODULE, Cmds, {H,S,R},
            aggregate(with_title('Commands'), command_names(Cmds),
            collect(eqc_lib:summary('Length'), length(Cmds),
            aggregate(with_title('Features'), eqc_statem:call_features(H),
            features(eqc_statem:call_features(H),
                R == ok)))))
      end)).
    
t() -> t(15).

t(Secs) ->
    eqc:quickcheck(eqc:testing_time(Secs, eqc_statem:show_states(prop_cluster_correct()))).

recheck() ->
    eqc:recheck(eqc_statem:show_states(prop_cluster_correct())).

cmds() ->
    eqc_cluster:commands(?MODULE).
    		
sample() ->
    eqc_gen:sample(cmds()).
   