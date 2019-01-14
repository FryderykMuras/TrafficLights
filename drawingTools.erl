%%%-------------------------------------------------------------------
%%% @author lukasz
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. sty 2019 11:46
%%%-------------------------------------------------------------------
-module(drawingTools).
-author("lukasz").

%% API
-export([drawRoads/2, drawGUI/0, printLightPair/4]).
-import(utils, [color/1, lightsCoords/1, print/1, gotoend/0, printxy/1, printlight/1, drawHorizontalRoad/3, drawVerticalRoad/4]).


% GUI drawing stuff
drawRoads(X, Y) ->
  % horizontal
  drawHorizontalRoad(X+0, 9, Y+5),
  drawHorizontalRoad(X+15, 20, Y+5),
  drawHorizontalRoad(X+40, 20, Y+5),
  drawHorizontalRoad(X+65, 9, Y+5),

  % vertical
  drawVerticalRoad(X+10, Y+1, Y+5, Y+1),
  drawVerticalRoad(X+10, Y+9, Y+13, Y+9),

  drawVerticalRoad(X+35, Y+1, Y+5, Y+1),
  drawVerticalRoad(X+35, Y+9, Y+13, Y+9),

  drawVerticalRoad(X+60, Y+1, Y+5, Y+1),
  drawVerticalRoad(X+60, Y+9, Y+13, Y+9).

%%drawLights(X,Y,C) ->
%%	printlight({X+6,Y+1,C}),
%%	printlight({X+6,Y+9,C}),
%%	printlight({X+16,Y+1,C}),
%%	printlight({X+16,Y+9,C}),
%%
%%	printlight({X+31,Y+1,C}),
%%	printlight({X+31,Y+9,C}),
%%	printlight({X+41,Y+1,C}),
%%	printlight({X+41,Y+9,C}),
%%
%%	printlight({X+56,Y+1,C}),
%%	printlight({X+56,Y+9,C}),
%%	printlight({X+66,Y+1,C}),
%%	printlight({X+66,Y+9,C}).

drawGUI() ->
  print({clear}),
  printxy({30,1,"Symulacja swiatel"}),
  drawRoads(0,1),
  %drawLights(0,1,color(X rem 4)),
  printxy({20,15,"Aby zakonczyc nacisnij q i Enter"}),
  gotoend().

printLightPair(0, X, Y, Color) ->
  printlight({X,Y+1,Color}),
  printlight({X+10,Y+9,Color});
printLightPair(1, X, Y, Color) ->
  printlight({X,Y+9,Color}),
  printlight({X+10,Y+1,Color}).