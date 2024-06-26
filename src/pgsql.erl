%%% File    : pgsql.erl
%%% Author  : Christian Sunesson <chsu79@gmail.com>
%%% Description : PostgresQL interface
%%% Created : 11 May 2005

%%
%% API for accessing the postgres driver.
%%

-module(pgsql).
-export([connect/1, connect/4, connect/5, connect/6]).

-export([squery/2, squery/3,
	pquery/3,
	terminate/1,
	prepare/3, unprepare/2,
	execute/3]).


connect(Host, Database, User, Password) ->
	connect([{database, Database},
		{host, Host},
		{user, User},
		{password, Password}]).

connect(Host, Database, User, Password, Port) ->
	connect([{database, Database},
		{host, Host},
		{user, User},
		{port, Port},
		{password, Password}]).

connect(Host, Database, User, Password, Port, ConnectTimeout) ->
	connect([{database, Database},
		{host, Host},
		{user, User},
		{port, Port},
		{password, Password},
		{connect_timeout, ConnectTimeout}]).

connect(Options) ->
	pgsql_proto:start(Options).

%% Close a connection
terminate(Db) ->
	gen_server:call(Db, terminate).

%%% In the "simple query" protocol, the frontend just sends a
%%% textual query string, which is parsed and immediately
%%% executed by the backend.

%% A simple query can contain multiple statements (separated with a semi-colon),
%% and each statement's response.

%%% squery(Db, Query) -> {ok, Results} | ... no real error handling
%%% Query = string()
%%% Results = [Result]
%%% Result = {"SELECT", RowDesc, ResultSet} | ...
squery(Db, Query) ->
	gen_server:call(Db, {squery, Query}, infinity).

%%% squery(Db, Query, Timeout) -> {ok, Results} | ... no real error handling
%%% Query = string()
%%% Timeout = milliseconds()
%%% Results = [Result]
%%% Result = {"SELECT", RowDesc, ResultSet} | ...
squery(Db, Query, Timeout) ->
	gen_server:call(Db, {squery, Query}, Timeout).

%%% In the "extended query" protocol, processing of queries is
%%% separated into multiple steps: parsing, binding of parameter
%%% values, and execution. This offers flexibility and performance
%%% benefits, at the cost of extra complexity.

%%% pquery(Db, Query, Params) -> {ok, Command, Status, NameTypes, Rows} | timeout | ...
%%% Query = string()
%%% Params = [term()]
%%% Command = string()
%%% Status = idle | transaction | failed_transaction
%%% NameTypes = [{ColName, ColType}]
%%% Rows = [list()]
pquery(Db, Query, Params) ->
	gen_server:call(Db, {equery, {Query, Params}}).

%%% prepare(Db, Name, Query) -> {ok, Status, ParamTypes, ResultTypes}
%%% Status = idle | transaction | failed_transaction
%%% ParamTypes = [atom()]
%%% ResultTypes = [{ColName, ColType}]
prepare(Db, Name, Query) ->
	gen_server:call(Db, {prepare, {Name, Query}}).

%%% unprepare(Db, Name) -> ok | timeout | ...
%%% Name = atom()
unprepare(Db, Name) ->
	gen_server:call(Db, {unprepare, Name}).

%%% execute(Db, Name, Params) -> {ok, Result} | timeout | ...
%%% Result = {'INSERT', NRows} |
%%%          {'DELETE', NRows} |
%%%          {'SELECT', ResultSet} |
%%%          ...
%%% ResultSet = [Row]
%%% Row = list()
execute(Db, Name, Params) when is_list(Params) ->
	gen_server:call(Db, {execute, {Name, Params}}).