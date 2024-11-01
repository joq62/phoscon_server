%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2023, c50
%%% @doc
%%% 
%%% @end
%%% Created : 18 Apr 2023 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(phoscon_server). 
 
-behaviour(gen_server).
%%--------------------------------------------------------------------
%% Include 
%%
%%--------------------------------------------------------------------

-include("log.api").

%% To be changed when create a new server
-include("phoscon_server.hrl").
-include("phoscon_server.rd").

%% API

-export([
	 set_state/4,
	 set_config/4,
	 get_maps/0,
	 get_maps/1
	 
	]).


%% admin




-export([
	 template_call/1,
	 template_cast/1,	 
	 start/0,
	 ping/0,
	 stop/0
	]).

-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3, format_status/2]).

-define(SERVER, ?MODULE).
		     
-record(state, {
		device_info,
		ip_addr,
		ip_port,
		crypto
	        
	       }).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
-spec get_maps()-> {ok,Maps::term()} |{error,Reason::term()}.
get_maps()->
    gen_server:call(?SERVER, {get_maps},infinity). 

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
-spec get_maps(DeviceType::string())-> {ok,Maps::term()} |{error,Reason::term()}.
get_maps(DeviceType)->
    gen_server:call(?SERVER, {get_maps,DeviceType},infinity). 
%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
-spec set_state(Id::string(),Key::string(),Value::term(),DeviceType::string())-> ok |{error,Reason::term()}.
set_state(Id,Key,Value,DeviceType)->
    gen_server:call(?SERVER, {set_state,Id,Key,Value,DeviceType},infinity). 

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
-spec set_config(Id::string(),Key::string(),Value::term(),DeviceType::string())-> ok |{error,Reason::term()}.
set_config(Id,Key,Value,DeviceType)->
    gen_server:call(?SERVER, {set_config,Id,Key,Value,DeviceType},infinity). 

%%----------- Templates and standards --------------------------------
%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
start()->
    application:start(?MODULE).

%%--------------------------------------------------------------------
%% @doc
%% Used to check if the application has started correct
%% @end
%%--------------------------------------------------------------------
-spec ping() -> pong | Error::term().
ping()-> 
    gen_server:call(?SERVER, {ping},infinity).

%%--------------------------------------------------------------------
%% @doc
%% Used to check if the application has started correct
%% @end
%%--------------------------------------------------------------------
-spec template_call(Args::term()) -> {ok,Year::integer(),Month::integer(),Day::integer()} | Error::term().
template_call(Args)-> 
    gen_server:call(?SERVER, {template_call,Args},infinity).
%%--------------------------------------------------------------------
%% @doc
%% Used to check if the application has started correct
%% @end
%%--------------------------------------------------------------------
-spec template_cast(Args::term()) -> ok.
template_cast(Args)-> 
    gen_server:cast(?SERVER, {template_cast,Args}).

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%% @end
%%--------------------------------------------------------------------
-spec start_link() -> {ok, Pid :: pid()} |
	  {error, Error :: {already_started, pid()}} |
	  {error, Error :: term()} |
	  ignore.
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).


%stop()-> gen_server:cast(?SERVER, {stop}).
stop()-> gen_server:stop(?SERVER).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%% @end
%%--------------------------------------------------------------------
-spec init(Args :: term()) -> {ok, State :: term()} |
	  {ok, State :: term(), Timeout :: timeout()} |
	  {ok, State :: term(), hibernate} |
	  {stop, Reason :: term()} |
	  ignore.

init([]) ->
    
    {ok, #state{
	    	    
	   },0}.


%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%% @end
%%--------------------------------------------------------------------
-spec handle_call(Request :: term(), From :: {pid(), term()}, State :: term()) ->
	  {reply, Reply :: term(), NewState :: term()} |
	  {reply, Reply :: term(), NewState :: term(), Timeout :: timeout()} |
	  {reply, Reply :: term(), NewState :: term(), hibernate} |
	  {noreply, NewState :: term()} |
	  {noreply, NewState :: term(), Timeout :: timeout()} |
	  {noreply, NewState :: term(), hibernate} |
	  {stop, Reason :: term(), Reply :: term(), NewState :: term()} |
	  {stop, Reason :: term(), NewState :: term()}.


handle_call({get_maps}, _From, State) ->
    ConbeeAddr=State#state.ip_addr,
    ConbeePort=State#state.ip_port,
    Crypto=State#state.crypto,
    LightsMaps=lib_phoscon:get_maps("lights",ConbeeAddr,ConbeePort,Crypto),
    SensorsMaps=lib_phoscon:get_maps("sensors",ConbeeAddr,ConbeePort,Crypto),
    Reply=[{"lights",LightsMaps},{"sensors",SensorsMaps}],
    {reply, Reply,State};

handle_call({get_maps,"lights"}, _From, State) ->
    ConbeeAddr=State#state.ip_addr,
    ConbeePort=State#state.ip_port,
    Crypto=State#state.crypto,
    Result=try lib_phoscon:get_maps("lights",ConbeeAddr,ConbeePort,Crypto)  of
	       {ok,MapsR}->
		   {ok,MapsR};
	       {error,ErrorR}->
		   {error,["M:F [A]) with reason",lib_phoscon,get_maps,["lights",ConbeeAddr,ConbeePort,Crypto]],"Reason=", ErrorR}
	   catch
	       Event:Reason:Stacktrace ->
		   {error,[#{event=>Event,
			     module=>?MODULE,
			     function=>?FUNCTION_NAME,
			     line=>?LINE,
			     args=>"lights",
			     reason=>Reason,
			     stacktrace=>[Stacktrace]}]}
	   end,
    Reply=case Result of
	      {ok,Maps}->
		  {ok,Maps};
	      {error,ErrorReason}->
		  {error,ErrorReason}
	  end,
    {reply, Reply,State};

handle_call({get_maps,"sensors"}, _From, State) ->
    ConbeeAddr=State#state.ip_addr,
    ConbeePort=State#state.ip_port,
    Crypto=State#state.crypto,
    Result=try lib_phoscon:get_maps("sensors",ConbeeAddr,ConbeePort,Crypto)  of
	       {ok,MapsR}->
		   {ok,MapsR};
	       {error,ErrorR}->
		   {error,["M:F [A]) with reason",lib_phoscon,get_maps,["sensors",ConbeeAddr,ConbeePort,Crypto]],"Reason=", ErrorR}
	   catch
	       Event:Reason:Stacktrace ->
		   {error,[#{event=>Event,
			     module=>?MODULE,
			     function=>?FUNCTION_NAME,
			     line=>?LINE,
			     args=>"lights",
			     reason=>Reason,
			     stacktrace=>[Stacktrace]}]}
	   end,
    Reply=case Result of
	      {ok,Maps}->
		  {ok,Maps};
	      {error,ErrorReason}->
		  {error,ErrorReason}
	  end,
    {reply, Reply,State};

handle_call({set_state,Id,Key,Value,"lights"}, _From, State) ->
    ConbeeAddr=State#state.ip_addr,
    ConbeePort=State#state.ip_port,
    Crypto=State#state.crypto,
    Result=try lib_phoscon:set_state(Id,Key,Value,"lights",ConbeeAddr,ConbeePort,Crypto)  of
	       {Status1, Headers1,Body1}->
		   {ok,Status1, Headers1,Body1};
	       {error,ErrorR}->
		   {error,["M:F [A]) with reason",lib_phoscon,set_state,[Id,Key,Value,"lights",ConbeeAddr,ConbeePort,Crypto]],"Reason=", ErrorR}
	   catch
	       Event:Reason:Stacktrace ->
		   {error,[#{event=>Event,
			     module=>?MODULE,
			     function=>?FUNCTION_NAME,
			     line=>?LINE,
			     args=>"lights",
			     reason=>Reason,
			     stacktrace=>[Stacktrace]}]}
	   end,
    Reply=case Result of
	      {ok,Status, Headers,Body}->
		  {ok,Status, Headers,Body};
	      {error,ErrorReason}->
		  {error,ErrorReason}
	  end,
    {reply, Reply,State};

handle_call({set_state,Id,Key,Value,"sensors"}, _From, State) ->
    ConbeeAddr=State#state.ip_addr,
    ConbeePort=State#state.ip_port,
    Crypto=State#state.crypto,
    Result=try lib_phoscon:set_state(Id,Key,Value,"sensors",ConbeeAddr,ConbeePort,Crypto)  of
	       {Status1, Headers1,Body1}->
		   {ok,Status1, Headers1,Body1};
	       {error,ErrorR}->
		   {error,["M:F [A]) with reason",lib_phoscon,set_state,[Id,Key,Value,"sensors",ConbeeAddr,ConbeePort,Crypto]],"Reason=", ErrorR}
	   catch
	       Event:Reason:Stacktrace ->
		   {error,[#{event=>Event,
			     module=>?MODULE,
			     function=>?FUNCTION_NAME,
			     line=>?LINE,
			     args=>"lights",
			     reason=>Reason,
			     stacktrace=>[Stacktrace]}]}
	   end,
    Reply=case Result of
	      {ok,Status, Headers,Body}->
		  {ok,Status, Headers,Body};
	      {error,ErrorReason}->
		  {error,ErrorReason}
	  end,
    {reply, Reply,State};


%%----- TemplateCode ---------------------------------------------------------------

handle_call({template_call,Args}, _From, State) ->
    Result=try erlang:apply(erlang,date,[])  of
	      {Y,M,D}->
		   {ok,Y,M,D};
	      {error,ErrorR}->
		   {error,["M:F [A]) with reason",erlang,date,[erlang,date,[]],"Reason=", ErrorR]}
	   catch
	       Event:Reason:Stacktrace ->
		   {error,[#{event=>Event,
			     module=>?MODULE,
			     function=>?FUNCTION_NAME,
			     line=>?LINE,
			     args=>Args,
			     reason=>Reason,
			     stacktrace=>[Stacktrace]}]}
	   end,
    Reply=case Result of
	      {ok,Year,Month,Day}->
		  NewState=State,
		  {ok,Year,Month,Day};
	      {error,ErrorReason}->
		  NewState=State,
		  {error,ErrorReason}
	  end,
    {reply, Reply,NewState};

%%----- Admin ---------------------------------------------------------------

handle_call({ping}, _From, State) ->
    Reply=pong,
    {reply, Reply, State};

handle_call(UnMatchedSignal, From, State) ->
   ?LOG_WARNING("Unmatched signal",[UnMatchedSignal]),
    io:format("unmatched_signal ~p~n",[{UnMatchedSignal, From,?MODULE,?LINE}]),
    Reply = {error,[unmatched_signal,UnMatchedSignal, From]},
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%% @end
%%--------------------------------------------------------------------


handle_cast({template_cast,Args}, State) ->
    Result=try erlang:apply(erlang,date,[])  of
	      {Year,Month,Day}->
		   {ok,Year,Month,Day};
	      {error,ErrorR}->
		   {error,["M:F [A]) with reason",erlang,date,[erlang,date,[]],"Reason=", ErrorR]}
	   catch
	       Event:Reason:Stacktrace ->
		   {error,[#{event=>Event,
			     module=>?MODULE,
			     function=>?FUNCTION_NAME,
			     line=>?LINE,
			     args=>Args,
			     reason=>Reason,
			     stacktrace=>[Stacktrace]}]}
	   end,
    case Result of
	{ok,_Year,_Month,_Day}->
	    NewState=State;
	{error,_ErrorReason}->
	    NewState=State
    end,
    {noreply, NewState};



handle_cast({stop}, State) ->
    
    {stop,normal,ok,State};

handle_cast(UnMatchedSignal, State) ->
    ?LOG_WARNING("Unmatched signal",[UnMatchedSignal]),
    io:format("unmatched_signal ~p~n",[{UnMatchedSignal,?MODULE,?LINE}]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%% @end
%%--------------------------------------------------------------------
-spec handle_info(Info :: timeout() | term(), State :: term()) ->
	  {noreply, NewState :: term()} |
	  {noreply, NewState :: term(), Timeout :: timeout()} |
	  {noreply, NewState :: term(), hibernate} |
	  {stop, Reason :: normal | term(), NewState :: term()}.



handle_info({gun_up,_,http}, State) -> 
    {noreply, State};

handle_info({gun_response,_,_,_,_,_}, State) -> 
    {noreply, State};

handle_info(timeout, State) ->

    initial_trade_resources(),
    ok=wait_for_host_server(),
    
    {ConbeeAddr,ConbeePort,ConbeeKey}=lib_phoscon:get_conbee_info(),
    application:ensure_all_started(gun),
    os:cmd("docker restart "++?ConbeeContainer),
    timer:sleep(5*1000),
    
    ?LOG_NOTICE("Server started ",
		[?MODULE,
		ip_addr,ConbeeAddr,
		ip_port,ConbeePort,
		crypto,ConbeeKey
		]),
    NewState=State#state{device_info=undefined,
			 ip_addr=ConbeeAddr,
			 ip_port=ConbeePort,
			 crypto=ConbeeKey},
    
    {noreply, NewState};

handle_info(Info, State) ->
    ?LOG_WARNING("Unmatched signal",[Info]),
    io:format("unmatched_signal ~p~n",[{Info,?MODULE,?LINE}]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%% @end
%%--------------------------------------------------------------------
-spec terminate(Reason :: normal | shutdown | {shutdown, term()} | term(),
		State :: term()) -> any().
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%% @end
%%--------------------------------------------------------------------
-spec code_change(OldVsn :: term() | {down, term()},
		  State :: term(),
		  Extra :: term()) -> {ok, NewState :: term()} |
	  {error, Reason :: term()}.
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called for changing the form and appearance
%% of gen_server status when it is returned from sys:get_status/1,2
%% or when it appears in termination error logs.
%% @end
%%--------------------------------------------------------------------
-spec format_status(Opt :: normal | terminate,
		    Status :: list()) -> Status :: term().
format_status(_Opt, Status) ->
    Status.

%%%===================================================================
%%% Internal functions
%%%===================================================================
-define(NumLoops,5).
-define(WaitTime,2000).
wait_for_host_server()->
    wait_for_host_server(?NumLoops,?WaitTime,false).

wait_for_host_server(_NumLoops,_WaitTime,ok)->
    ok;
wait_for_host_server(0,_,Acc) ->
    Acc;
wait_for_host_server(NumLoops,WaitTime,false)->
    io:format(" get_local_resource_tuples  ~p~n",[{rd_store: get_local_resource_tuples(),?MODULE,?LINE}]),
    io:format("get_target_resource_types  ~p~n",[{rd_store:get_target_resource_types(),?MODULE,?LINE}]),
    io:format("get_all_resources  ~p~n",[{rd_store:get_all_resources(),?MODULE,?LINE}]),
    io:format("get_resource_types() ~p~n",[{rd_store:get_resource_types(),?MODULE,?LINE}]),
    io:format("rd:fetch_resources(host_server) ~p~n",[{rd:fetch_resources(host_server),?MODULE,?LINE}]),
    case rd:fetch_resources(host_server) of
	[]->
	    timer:sleep(WaitTime),
	    Acc=false;
	[{host_server,_}|_] ->
	    Acc=ok
    end,
    wait_for_host_server(NumLoops-1,WaitTime,Acc).


initial_trade_resources()->
    [rd:add_local_resource(ResourceType,Resource)||{ResourceType,Resource}<-?LocalResourceTuples],
    [rd:add_target_resource_type(TargetType)||TargetType<-?TargetTypes],

%    [rd:add_local_resource(ResourceType,Resource)||{ResourceType,Resource}<-[]],
%    [rd:add_target_resource_type(TargetType)||TargetType<-[]],
    rd:trade_resources(),
    timer:sleep(3000).
