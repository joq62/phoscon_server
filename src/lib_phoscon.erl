%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :  
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(lib_phoscon).    
     
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
%-include("device.spec").
%% --------------------------------------------------------------------

%% External exports
-export([

%	 all_light_maps/3,
%	 all_sensor_maps/3,
	 get_conbee_info/0,	 
	 what_devices/4,
	 get_maps/4,
	 set_state/7
	]). 


%% ====================================================================
%% External functions
%% ====================================================================

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
get_conbee_info()->
    {ok,ApplicationConfigs}=rd:call(host_server,host_server,get_application_config,[],5000),
    [{ConbeeAddr,ConbeePort,ConbeeKey}]=[{ConbeeAddr,ConbeePort,ConbeeKey}||{conbee,[{conbee_addr,ConbeeAddr},{conbee_port,ConbeePort},{conbee_key,ConbeeKey}]}<-ApplicationConfigs],

%	   glurk={conbee,[{conbee_addr,"172.17.0.2"},{conbee_port,80},{conbee_key,"Glurk"}]ApplicationConfigs,
   
    {ConbeeAddr,ConbeePort,ConbeeKey}.

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
get_maps("sensors",ConbeeAddr,ConbeePort,Crypto)->
    get("sensors",ConbeeAddr,ConbeePort,Crypto);
get_maps("lights",ConbeeAddr,ConbeePort,Crypto)->
    get("lights",ConbeeAddr,ConbeePort,Crypto);
get_maps(NoMatch,_,_,_)->
    {error,[NoMatch,?MODULE,?FUNCTION_NAME,?LINE]}.

get(DeviceType,ConbeeAddr,ConbeePort,Crypto)->
    {ok, ConnPid} = gun:open(ConbeeAddr,ConbeePort),
    Cmd="/api/"++Crypto++"/"++DeviceType,
    Ref=gun:get(ConnPid,Cmd),
  %  Result= get_info(gun:await_body(ConnPid, Ref)),
    Result= case gun:await_body(ConnPid, Ref) of
		{ok,Body}->
		    {ok,jsx:decode(Body,[])};
		Reason ->
		    {error,[Reason,?MODULE,?LINE]}
	    end,
    ok=gun:close(ConnPid),
    Result.

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
what_devices("lights",Ip,Port,Crypto)->
    Maps=get_maps(<<"lights">>,Ip,Port,Crypto),
    Maps;
what_devices("sensors",Ip,Port,Crypto)->
    Maps=get_maps(<<"sensors">>,Ip,Port,Crypto),
    Maps.



%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
set_state(Id,Key,Value,DeviceType,Ip,Port,Crypto)->
    Cmd="/api/"++Crypto++"/"++DeviceType++"/"++Id++"/state",
    Body=jsx:encode(#{Key => Value}),
    {ok, ConnPid} = gun:open(Ip,Port),
    StreamRef = gun:put(ConnPid, Cmd, 
			[{<<"content-type">>, "application/json"}],Body),
    Result=get_reply(ConnPid,StreamRef),
    ok=gun:close(ConnPid),
    Result.

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
get_reply(ConnPid,StreamRef)->
    case gun:await(ConnPid, StreamRef) of
	{response, fin, Status, Headers} ->
%	    io:format(" no_data ~p~n", [{?MODULE,?LINE}]),
	    Body=[no_data];
	{response, nofin, Status, Headers} ->
%	    io:format(" ~p~n", [{?MODULE,?LINE}]),
	    {ok, Body} = gun:await_body(ConnPid, StreamRef),
	    Body
    end,
    {Status, Headers,Body}.
