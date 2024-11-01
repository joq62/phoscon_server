%%%-------------------------------------------------------------------
%% @doc application_server public API
%% @end
%%%-------------------------------------------------------------------

-module(phoscon_server_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    phoscon_server_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
