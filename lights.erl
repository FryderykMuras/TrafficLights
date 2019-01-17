-module(lights).
-export([keyboardListener/1, lightsPair/4, main/0, intersectionModelLoop/7, shiftcar/3,shifter/1,counter/7]).
-import(drawingTools, [drawRoads/2, drawGUI/0, printLightPair/4]).
-import(utils, [color/1, lightsCoords/1, print/1, gotoend/0, printxy/1, printlight/1, drawHorizontalRoad/3, drawVerticalRoad/4]).

keyboardListener (MainPID) ->
  gotoend(),
  Char = io:get_chars("", 1),
	case Char of
		"q" -> MainPID!{self(),Char};
		"t" -> printxy({0,20," "}), MainPID!{self(),Char}, keyboardListener(MainPID);
		_ -> printxy({0,20," "}), keyboardListener(MainPID)
	end.

lightsPair(Id, X, Y, Color) ->
	receive
    {changecolor, toRed, CorrespondingPairPID,VertGreen,IntersectionPID} ->
			if
				VertGreen =:= 1-> IntersectionPID!{vertGreen, VertGreen};
				true -> pass
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
				true -> pass
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
												 true -> pass
											 end,
			1;
		true -> if
              GreenTimer =/= 0-> intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, 0, CounterPid, ShifterPID);
              true -> pass
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

		setred ->
			case VertGreen of
				1 ->
					%VertLightPid!{changecolor,toRed,HorLightPid,0,self()},
					intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, GreenTimer+GTm, CounterPid,ShifterPID);
				0 ->
					HorLightPid!{changecolor,toRed,VertLightPid,1,self()},
					intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, GreenTimer+GTm, CounterPid,ShifterPID)
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
  IntersectionPids = [intersectionModelInit(N) || N<-[0,1,2]],
	Shifter = spawn(?MODULE,shifter,[IntersectionPids]),
	lists:map(fun(Z) -> Z!{shifter,Shifter}, Z end, IntersectionPids),
	main(1, ListenerPID, IntersectionPids, 1).

% Mode = 1 -> zielona fala w prawo, -1 -> w lewo
main(Mode, ListenerPID, IntersectionPids, X) ->
	[FirstInter, MiddleInter, LastInter] = IntersectionPids,
%%	if
%%		((X - 2*100) rem (23*100) =:= 0) or ((X - 2*100 - 19*100) rem (23*100) =:= 0) ->
%%			FirstInter!togglelights,
%%			LastInter!togglelights;
%%		((X - 2*100 - 350) rem (23*100) =:= 0) or ((X - 2*100 - 1400) rem (23*100) =:= 0)->
%%			MiddleInter!togglelights;
%%		true -> ok
%%	end,

	case Mode of
		  1 ->
				FirstChanging = FirstInter,
				LastChanging = LastInter,
				ProbL = 100,
				ProbR = 180;
			-1 ->
				FirstChanging = LastInter,
				LastChanging = FirstInter,
				ProbL = 180,
				ProbR = 100
	end,

	if
		((X - 2*100) >= 0) and (((X - 2*100) rem (18*100) =:= 0) or ((X - 2*100 - 8*100) rem (18*100) =:= 0)) ->
		FirstChanging!togglelights;
		((X - 2*100 - 450) >= 0) and (((X - 2*100 - 450) rem (18*100) =:= 0) or ((X - 2*100 - 1250) rem (18*100) =:= 0))->
		MiddleInter!togglelights;
		((X - 2*100 - 9*100) >= 0) and (((X - 2*100 - 9*100) rem (18*100) =:= 0) or ((X - 2*100 - 17*100) rem (18*100) =:= 0))->
		LastChanging!togglelights;
		true -> ok
	end,

	L = rand:uniform(ProbL),
	R= rand:uniform(ProbR),
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
			timer:sleep(1000),
			print({clear}),
			print({gotoxy,1,1}),
			print({showCursor}),
			ok;
		{ListenerPID, "t"} ->
			FirstInter!setred,
			MiddleInter!setred,
			LastInter!setred,
			%timer:sleep(500),
			case Mode of
				  1 ->   printxy({47,16, "<--"});
					-1 ->   printxy({47,16, "-->"})
			end,
			main(-Mode, ListenerPID, IntersectionPids, 1)
	after 10 ->
		main(Mode, ListenerPID, IntersectionPids, X+1)
	end.