%%%-------------------------------------------------------------------
%%% @author lukasz
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. sty 2019 11:45
%%%-------------------------------------------------------------------
-module(utils).
-author("lukasz").

%% API
-export([color/1, lightsCoords/1, print/1, gotoend/0, printxy/1, printlight/1, drawHorizontalRoad/3, drawVerticalRoad/4]).

% utils
% \e[X;YH - przesunięcie kursora do X Y
% \e[2J - czyszczenie ekranu

lightsCoords(0) -> 6;
lightsCoords(1) -> 31;
lightsCoords(2) -> 56.

% colors
color(0) -> red;
color(1) -> redamber;
color(2) -> green;
color(3) -> amber.

% goto and clearing
print({gotoxy,X,Y}) ->
  io:format("\e[~p;~pH",[Y,X]);
print({clear}) ->
  io:format("\e[2J",[]);
print({hideCursor}) ->
  io:format("\e[?25l",[]);
print({showCursor})->
  io:format("\e[?25h",[]).
gotoend() ->
  print({gotoxy,0,16}).

% color printing
printxy({X,Y,Msg}) ->
  io:format("\e[~p;~pH~s~n",[Y,X,Msg]).
%%printintxy({X,Y,Msg}) ->
%%  io:format("\e[~p;~pH~p~n",[Y,X,Msg]).
printredxy({X,Y,Msg}) ->
  io:format("\e[~p;~pH\e[91m~p~n\e[0m",[Y,X,Msg]).
printamberxy({X,Y,Msg}) ->
  io:format("\e[~p;~pH\e[93m~p~n\e[0m",[Y,X,Msg]).
printgreenxy({X,Y,Msg}) ->
  io:format("\e[~p;~pH\e[92m~p~n\e[0m",[Y,X,Msg]).

% drawing lights
printlight({X,Y,red}) ->
  printxy({X+1,Y,"_"}),
  printxy({X,Y+1,"|"}),
  printredxy({X+1,Y+1,o}),
  printxy({X+2,Y+1,"|"}),
  printxy({X,Y+2,"| |"}),
  printxy({X,Y+3,"| |"}),
  printxy({X+1,Y+3,"_"});
printlight({X,Y,amber}) ->
  printxy({X+1,Y,"_"}),
  printxy({X,Y+1,"| |"}),
  printxy({X,Y+2,"|"}),
  printamberxy({X+1,Y+2,o}),
  printxy({X+2,Y+2,"|"}),
  printxy({X,Y+3,"| |"}),
  printxy({X+1,Y+3,"_"});
printlight({X,Y,redamber}) ->
  printxy({X+1,Y,"_"}),
  printxy({X,Y+1,"|"}),
  printredxy({X+1,Y+1,o}),
  printxy({X+2,Y+1,"|"}),
  printxy({X,Y+2,"|"}),
  printamberxy({X+1,Y+2,o}),
  printxy({X+2,Y+2,"|"}),
  printxy({X,Y+3,"| |"}),
  printxy({X+1,Y+3,"_"});
printlight({X,Y,green}) ->
  printxy({X+1,Y,"_"}),
  printxy({X,Y+1,"| |"}),
  printxy({X,Y+2,"| |"}),
  printxy({X,Y+3,"|"}),
  printgreenxy({X+1,Y+3,o}),
  printxy({X+2,Y+3,"|"}).
%	printxy({X+1,Y+3,"_"}).


% roads drawing
drawHorizontalRoad(Xp, Dl, Y) ->
  io:format("\e[~p;~pH~*.._s~n",[Y,Xp, Dl, ""]),
  io:format("\e[~p;~pH~*..-s~n",[Y+2,Xp, Dl, ""]),
  io:format("\e[~p;~pH~*.._s~n",[Y+3,Xp, Dl, ""]).
drawVerticalRoad(X, YPocz, YKonc, Y) when Y< YKonc ->
  printxy({X,Y,"| | |"}),
  drawVerticalRoad(X, YPocz, YKonc, Y+1);
drawVerticalRoad(X, _, Y, Y) ->
  printxy({X,Y,"| | |"}).