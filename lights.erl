-module(lights).
-compile(export_all).
%-export([main/0, keyboardListener/1]).
%-import(utils).

%--------------------------------------------
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
	io:format("\e[2J",[]).
gotoend() ->
	print({gotoxy,0,16}).
      
% color printing
printxy({X,Y,Msg}) ->
	io:format("\e[~p;~pH~s~n",[Y,X,Msg]).
printintxy({X,Y,Msg}) ->
  io:format("\e[~p;~pH~p~n",[Y,X,Msg]).
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
	
%--------------------------------------------
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
	
%---------------------------------------
% simulation part
keyboardListener (MainPID) ->
  gotoend(),
  Char = io:get_chars("", 1),
  MainPID!{self(),Char}.

lightsPair(Id, X, Y, Color) ->
	receive
    {changecolor, NewColor} ->
			printLightPair(Id, X, Y, NewColor),
			lightsPair(Id, X, Y, NewColor);
    print ->
      printLightPair(Id, X, Y, Color),
      lightsPair(Id, X, Y, Color)
	end.

counterInit(Id)->
	X = lightsCoords(Id),
	Y = 8,
	spawn(?MODULE,counter,[X,Y,0,0]).

counter(X,Y,Lvalue,Rvalue)->
	printxy({X+1, Y+1, integer_to_list(Lvalue)}),
	printxy({X+11 , Y-1, integer_to_list(Rvalue)}),
	receive
		lcounterp ->
			counter(X,Y,Lvalue+1,Rvalue);
		rcounterp ->
			counter(X,Y,Lvalue,Rvalue+1)

	end.


intersectionModelInit(Id) ->
	CounterPid = counterInit(Id),
  VertLightPid = spawn(?MODULE, lightsPair, [0, lightsCoords(Id), 1, green]),
  HorLightPid = spawn(?MODULE, lightsPair, [1, lightsCoords(Id), 1, red]),
  VertLightPid!print,
  HorLightPid!print,
	spawn(?MODULE, intersectionModelLoop,[Id, VertLightPid, HorLightPid, 1,CounterPid]).
	
intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, CounterPid) ->
	receive
		newcarL->
			CounterPid!lcounterp,
			intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, CounterPid);

		newcarR->
			CounterPid!rcounterp,
			intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, CounterPid);

    togglelights ->
      case VertGreen of
        1 ->
          VertLightPid!{changecolor,amber},
          timer:sleep(1000),
          VertLightPid!{changecolor,red},
          %timer:sleep(200),
          HorLightPid!{changecolor,redamber},
          timer:sleep(1000),
          HorLightPid!{changecolor,green},
          intersectionModelLoop(Id, VertLightPid, HorLightPid, 0, CounterPid);
        0 ->
          HorLightPid!{changecolor,amber},
          timer:sleep(1000),
          HorLightPid!{changecolor,red},
          %timer:sleep(200),
          VertLightPid!{changecolor,redamber},
          timer:sleep(1000),
          VertLightPid!{changecolor,green},
          intersectionModelLoop(Id, VertLightPid, HorLightPid, 1, CounterPid)
      end;
    printlights ->
      VertLightPid!print,
      HorLightPid!print,
      intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, CounterPid)
	end.



main() ->
  drawGUI(),
	ListenerPID = spawn(?MODULE, keyboardListener, [self()]),
  %ListenerPID = 0,
  IntersectionPids = [intersectionModelInit(N) || N<-[0,1,2]],
  %P = [intersectionModelInit(N) || N<-[0,1,2]].
  %io:format("~p~n",[IntersectionPids]),
	main(ListenerPID, IntersectionPids, 1).
main(ListenerPID, IntersectionPids, X) ->
  %X=1,
  %timer:sleep(2000),
  %main(ListenerPID, X+1).
  NewIntersectionPids = if
                          (X rem 800) =:= 0 -> lists:map(fun(Z) -> Z!togglelights, Z end, IntersectionPids);
													true -> IntersectionPids
                        end,
	First = lists:nth(1,IntersectionPids),
	Last = lists:nth(3, IntersectionPids),
	G = rand:uniform(100),
	H = rand:uniform(100),
	if
		G < 2 -> First!newcarL;
		true -> First
	end,
	if
		H < 2 -> Last!newcarR;
		true -> Last
	end,

%lists:map(fun(Z) -> Z!printlights, Z end, IntersectionPids),
  %printintxy({6,3, X}),
  gotoend(),
  receive
		  {ListenerPID, "q"} ->
				io:format("\ec"),
				ok
	  after 10 -> %co 100 cykli mija sekunda
		  main(ListenerPID, IntersectionPids, X+1)
	  end.
%main(_,_,_) -> ok.

   
      
