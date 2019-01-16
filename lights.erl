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
    {changecolor, toRed, CorrespondingPairPID,VertGreen,IntersectionPID} ->
			if
				VertGreen =:= 1-> IntersectionPID!{vertGreen, VertGreen};
				true ->0
			end,
			printLightPair(Id, X, Y, amber),
			timer:sleep(1000),
			printLightPair(Id, X, Y, red),
			CorrespondingPairPID!{changecolor, toGreen, VertGreen, IntersectionPID},
			lightsPair(Id, X, Y, red);
		{changecolor, toGreen, VertGreen, IntersectionPID} ->
			printLightPair(Id, X, Y, redamber),
			timer:sleep(1000),
			printLightPair(Id, X, Y, green),
			if
				VertGreen =:= 0-> IntersectionPID!{vertGreen, VertGreen};
				true ->0
			end,
			lightsPair(Id, X, Y, green);
    print ->
      printLightPair(Id, X, Y, Color),
      lightsPair(Id, X, Y, Color);
		quit -> ok
	end.

counterInit(Id)->
	X = lightsCoords(Id),
	Y = 8,
	spawn(?MODULE,counter,[X,Y,0,0,0,Id,null]).

counter(X,Y,Lvalue,Rvalue,MainCounter,Id,Shifter)->
	printxy({X+1, Y+1, lists:append(integer_to_list(Lvalue),"__")}),
	printxy({X+11 , Y-1, lists:append(integer_to_list(Rvalue),"   ")}),
	printxy({X+6, Y, lists:append(integer_to_list(MainCounter),"   ")}),

	receive
    {green} ->
			R=if
					Rvalue > 0 -> Shifter!{Id-1,r,5000},
						-1;
					true ->  0
				end,
			L=if
					Lvalue > 0 -> Shifter!{Id+1,l,5000},
						-1;
					true ->  0
				end,
			counter(X,Y,Lvalue+L,Rvalue+R,MainCounter-(L+R),Id,Shifter);


		{shifterPID,PID} ->
			counter(X,Y,Lvalue,Rvalue,MainCounter,Id,PID);
		lcounter ->
			counter(X,Y,Lvalue+1,Rvalue,MainCounter,Id,Shifter);
		rcounter ->
			counter(X,Y,Lvalue,Rvalue+1,MainCounter,Id,Shifter);
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
		VertGreen =:= 0 -> if
												 (GreenTimer rem 4) =:= 0  -> CounterPid!{green} ;
												 true -> 0
											 end,
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
			CounterPid!lcounter,
			intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, GreenTimer+GTm, CounterPid,ShifterPID);

		newcarR->
			CounterPid!rcounter,
			intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, GreenTimer+GTm, CounterPid,ShifterPID);

    togglelights ->
      case VertGreen of
        1 ->
          VertLightPid!{changecolor,toRed,HorLightPid,0,self()},
          intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, GreenTimer+GTm, CounterPid,ShifterPID);
        0 ->
          HorLightPid!{changecolor,toRed,VertLightPid,1,self()},
          intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, GreenTimer+GTm, CounterPid,ShifterPID)
      end;
		{vertGreen, VG}->
			intersectionModelLoop(Id, VertLightPid, HorLightPid, VG, GreenTimer+GTm, CounterPid,ShifterPID);
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


	%przełączanie świateł
	[FirstInter, MiddleInter, LastInter] = IntersectionPids,
	if
		%((X - 2*100) rem (17*100) =:= 0) or ((X - 2*100 - 11*100) rem (17*100) =:= 0) ->
		((X - 2*100) rem (23*100) =:= 0) or ((X - 2*100 - 19*100) rem (23*100) =:= 0) ->
			FirstInter!togglelights,
			LastInter!togglelights;
		%(X - 2*100 - 450) rem (850) =:= 0 ->
		((X - 2*100 - 350) rem (23*100) =:= 0) or ((X - 2*100 - 1400) rem (23*100) =:= 0)->
			MiddleInter!togglelights;
		true -> ok
	end,



	%generowanie samochodów na skrajnych skrzyżowaniach
	L = rand:uniform(130),
	R= rand:uniform(130),
	if
		L < 2 -> FirstInter!newcarL;
		true -> FirstInter
	end,
	if
		R < 2 -> LastInter!newcarR;
		true -> LastInter
	end,

  gotoend(),
  receive
		  {ListenerPID, "q"} ->
				lists:map(fun(Z) -> Z!quit, Z end, IntersectionPids),
				%io:format("\ec"),
				timer:sleep(3000),
				print({gotoxy,0,16}),
				print({showCursor}),
				ok
	  after 10 -> %co 100 cykli mija sekunda
		  main(ListenerPID, IntersectionPids, X+1)
	  end.


   
      
