-module(drawingTools).
-export([drawRoads/2, drawGUI/0, printLightPair/4]).
-import(utils, [color/1, lightsCoords/1, print/1, gotoend/0, printxy/1, printlight/1, drawHorizontalRoad/3, drawVerticalRoad/4]).


drawRoads(X, Y) ->
  drawHorizontalRoad(X+0, 9, Y+5),
  drawHorizontalRoad(X+15, 20, Y+5),
  drawHorizontalRoad(X+40, 20, Y+5),
  drawHorizontalRoad(X+65, 9, Y+5),

  drawVerticalRoad(X+10, Y+1, Y+5, Y+1),
  drawVerticalRoad(X+10, Y+9, Y+13, Y+9),

  drawVerticalRoad(X+35, Y+1, Y+5, Y+1),
  drawVerticalRoad(X+35, Y+9, Y+13, Y+9),

  drawVerticalRoad(X+60, Y+1, Y+5, Y+1),
  drawVerticalRoad(X+60, Y+9, Y+13, Y+9).

drawGUI() ->
  print({clear}),
  printxy({30,1,"Symulacja swiatel"}),
  drawRoads(0,1),
  printxy({23,16, "Kierunek zielonej fali: "}),
  printxy({47,16, "-->"}),
  printxy({1,17,"-------------------------------------------------------------------------"}),
  printxy({20,18,"Aby zakonczyc nacisnij q i Enter"}),
  printxy({17,19,"Aby zmienic kierunek nacisnij t i Enter"}),
  gotoend().

printLightPair(0, X, Y, Color) ->
  printlight({X,Y+1,Color}),
  printlight({X+10,Y+9,Color});
printLightPair(1, X, Y, Color) ->
  printlight({X,Y+9,Color}),
  printlight({X+10,Y+1,Color}).