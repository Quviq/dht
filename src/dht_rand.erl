-module(dht_rand).

-export([pick/1]).
-export([crypto_rand_bytes/1, uniform/1]).

pick([]) -> [];
pick(Items) ->
    Len = length(Items),
    Pos = rand:uniform(Len),
    lists:nth(Pos, Items).

crypto_rand_bytes(N) ->
    crypto:rand_bytes(N).

uniform(N) -> rand:uniform(N).
