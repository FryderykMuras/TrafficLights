-module(lights).
-compile(export_all).
%-export([main/0, keyboardListener/1]).
%-import(utils).
-import(drawingTools, [drawRoads/2, drawGUI/0, printLightPair/4]).
-import(utils, [color/1, lightsCoords/1, print/1, gotoend/0, printxy/1, printlight/1, drawHorizontalRoad/3, drawVerticalRoad/4]).

%--------------------------------------------

	
%--------------------------------------------

	
%---------------------------------------
% simulation part
keyboardListener (MainPID) ->
  gotoend(),
  Char = io:get_chars("", 1),
	case Char of
		"q" -> MainPID!{self(),Char};
		_ -> keyboardListener(MainPID)
	end.

lightsPair(Id, X, Y, Color) ->
	receive
    {changecolor, NewColor} ->
			printLightPair(Id, X, Y, NewColor),
			lightsPair(Id, X, Y, NewColor);
    print ->
      printLightPair(Id, X, Y, Color),
      lightsPair(Id, X, Y, Color);
		quit -> ok
	end.

counterInit(Id)->
	X = lightsCoords(Id),
	Y = 8,
	spawn(?MODULE,counter,[X,Y,0,0,Id,null]).

counter(X,Y,Lvalue,Rvalue,Id,Shifter)->
	printxy({X+1, Y+1, lists:append(integer_to_list(Lvalue),"__ ")}),
	printxy({X+11 , Y-1, lists:append(integer_to_list(Rvalue),"   ")}),


	receive
    {green,Timer} ->
      if
        (Timer rem 6) =:= 0 -> R=if
                                    Rvalue > 0 -> Shifter!{Id-1,r,5000},
                                      -1;
                                    true ->  0
                                  end,
                                L=if
                                    Lvalue > 0 -> Shifter!{Id+1,l,5000},
                                      -1;
                                    true ->  0
                                  end,
            counter(X,Y,Lvalue+L,Rvalue+R,Id,Shifter);
        true -> counter(X,Y,Lvalue,Rvalue,Id,Shifter)
      end;

		{shifterPID,PID} ->
			counter(X,Y,Lvalue,Rvalue,Id,PID);
		lcounterp ->
			counter(X,Y,Lvalue+1,Rvalue,Id,Shifter);
		rcounterp ->
			counter(X,Y,Lvalue,Rvalue+1,Id,Shifter);
		quit -> ok

	end.


intersectionModelInit(Id) ->
	CounterPid = counterInit(Id),
  VertLightPid = spawn(?MODULE, lightsPair, [0, lightsCoords(Id), 1, green]),
  HorLightPid = spawn(?MODULE, lightsPair, [1, lightsCoords(Id), 1, red]),
  VertLightPid!print,
  HorLightPid!print,
	spawn(?MODULE, intersectionModelLoop,[Id, VertLightPid, HorLightPid, 1, 0, CounterPid,null]).
	
intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, GreenTimer, CounterPid, ShifterPID) ->
	GTm = if
		VertGreen =:= 0 -> CounterPid!{green,GreenTimer},
      1;
		true -> if
              GreenTimer =/= 0-> intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, 0, CounterPid, ShifterPID);
              true ->0
            end,
      0
	end,
	receive
		{shifter, PID}->
			CounterPid!{shifterPID,PID},
			intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, GreenTimer+GTm, CounterPid,PID);

		newcarL->
			CounterPid!lcounterp,
			intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, GreenTimer+GTm, CounterPid,ShifterPID);

		newcarR->
			CounterPid!rcounterp,
			intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, GreenTimer+GTm, CounterPid,ShifterPID);

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
          intersectionModelLoop(Id, VertLightPid, HorLightPid, 0, GreenTimer+GTm, CounterPid,ShifterPID);
        0 ->
          HorLightPid!{changecolor,amber},
          timer:sleep(1000),
          HorLightPid!{changecolor,red},
          %timer:sleep(200),
          VertLightPid!{changecolor,redamber},
          timer:sleep(1000),
          VertLightPid!{changecolor,green},
          intersectionModelLoop(Id, VertLightPid, HorLightPid, 1, GreenTimer+GTm, CounterPid,ShifterPID)
      end;
    printlights ->
      VertLightPid!print,
      HorLightPid!print,
      intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, GreenTimer+GTm, CounterPid,ShifterPID);
		quit ->
			VertLightPid!quit,
			HorLightPid!quit,
			CounterPid!quit,
			ShifterPID!quit

	after 100 -> intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, GreenTimer+GTm, CounterPid,ShifterPID)
	end.



shifter(InterPIDs)->
	receive
		{ID,r,Delay}->
			if
				ID < 0 ->
					shifter(InterPIDs);
				ID > 2 ->
					shifter(InterPIDs);
				true -> spawn(?MODULE,shiftcar,[lists:nth(ID+1,InterPIDs),1,Delay]),%w list:nth() indeksujemy od 1
					shifter(InterPIDs)
			end;

		{ID,l,Delay}->
			if
				ID < 0 ->
					shifter(InterPIDs);
				ID > 2 ->
					shifter(InterPIDs);
				true -> spawn(?MODULE,shiftcar,[lists:nth(ID+1,InterPIDs),0,Delay]),%w list:nth() indeksujemy od 1
					shifter(InterPIDs)
			end;
		quit -> ok
	end.

shiftcar(PID,Direction,Delay)->
	timer:sleep(Delay),
	if
		Direction =:= 0 -> PID!newcarL;
		true -> PID!newcarR
	end.

main() ->
  drawGUI(),
	print({hideCursor}),
	ListenerPID = spawn(?MODULE, keyboardListener, [self()]),
  %ListenerPID = 0,
  IntersectionPids = [intersectionModelInit(N) || N<-[0,1,2]],
	Shifter = spawn(?MODULE,shifter,[IntersectionPids]),
	lists:map(fun(Z) -> Z!{shifter,Shifter}, Z end, IntersectionPids),
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
	
	%sterowanie przełączaniem świateł
%%	if
%%		X rem 800 -> ;
%%		true ->
%%	end


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
				lists:map(fun(Z) -> Z!quit, Z end, IntersectionPids),
				%io:format("\ec"),
				print({showCursor}),
				ok
	  after 10 -> %co 100 cykli mija sekunda
		  main(ListenerPID, IntersectionPids, X+1)
	  end.
%main(_,_,_) -> ok.

   
      
