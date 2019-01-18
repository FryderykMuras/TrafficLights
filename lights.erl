-module(lights).
-export([logPrinter/1,to_timestamp/1,keyboardListener/2, lightsPair/5, main/0, intersectionModelLoop/8, shiftcar/3,shifter/1,counter/8,printer/0]).
-import(drawingTools, [drawRoads/2, drawGUI/0, printLightPair/4]).
-import(utils, [color/1, lightsCoords/1, print/1, gotoend/0, printxy/1, printlight/1, drawHorizontalRoad/3, drawVerticalRoad/4]).

keyboardListener (MainPID,PrinterPID) ->
  gotoend(),
  Char = io:get_chars("", 1),
	case Char of
		"q" -> MainPID!{self(),Char};
		"t" -> PrinterPID!{printxy,0,20," "}, MainPID!{self(),Char}, keyboardListener(MainPID,PrinterPID);
		_ -> PrinterPID!{printxy,0,20," "},
			keyboardListener(MainPID,PrinterPID)
	end.

lightsPair(Id, X, Y, Color, PrinterPID) ->
	receive
    {changecolor, toRed, CorrespondingPairPID,VertGreen,IntersectionPID} ->
			if
				VertGreen =:= 1-> IntersectionPID!{vertGreen, VertGreen};
				true -> pass
			end,
			PrinterPID!{printLightPair,Id, X, Y, amber},
			timer:sleep(1000),
			PrinterPID!{printLightPair,Id, X, Y, red},
			CorrespondingPairPID!{changecolor, toGreen, VertGreen, IntersectionPID},
			lightsPair(Id, X, Y, red, PrinterPID);
		{changecolor, toGreen, VertGreen, IntersectionPID} ->
			PrinterPID!{printLightPair,Id, X, Y, redamber},
			timer:sleep(1000),
			PrinterPID!{printLightPair,Id, X, Y, green},
			if
				VertGreen =:= 0-> IntersectionPID!{vertGreen, VertGreen};
				true -> pass
			end,
			lightsPair(Id, X, Y, green, PrinterPID);
    print ->
			PrinterPID!{printLightPair,Id, X, Y, Color},
      lightsPair(Id, X, Y, Color, PrinterPID);
		quit -> ok
	end.

counterInit(Id, PrinterPID)->
	X = lightsCoords(Id),
	Y = 8,
	spawn(?MODULE,counter,[X,Y,0,0,0,Id,null,PrinterPID]).

counter(X,Y,Lvalue,Rvalue,MainCounter,Id,Shifter, PrinterPID)->
	PrinterPID!{printxy,X+1, Y+1, lists:append(integer_to_list(Lvalue),"__")},
	PrinterPID!{printxy,X+11, Y-1, lists:append(integer_to_list(Rvalue),"   ")},
	PrinterPID!{printxy,X+6, Y, lists:append(integer_to_list(MainCounter),"   ")},

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
			counter(X,Y,Lvalue+L,Rvalue+R,MainCounter-(L+R),Id,Shifter, PrinterPID);

		{shifterPID,PID} ->
			counter(X,Y,Lvalue,Rvalue,MainCounter,Id,PID, PrinterPID);
		lcounter ->
			counter(X,Y,Lvalue+1,Rvalue,MainCounter,Id,Shifter, PrinterPID);
		rcounter ->
			counter(X,Y,Lvalue,Rvalue+1,MainCounter,Id,Shifter, PrinterPID);
		quit -> ok

	end.

intersectionModelInit(Id,PrinterPID) ->
	CounterPid = counterInit(Id, PrinterPID),
  VertLightPid = spawn(?MODULE, lightsPair, [0, lightsCoords(Id), 1, green, PrinterPID]),
  HorLightPid = spawn(?MODULE, lightsPair, [1, lightsCoords(Id), 1, red, PrinterPID]),
  VertLightPid!print,
  HorLightPid!print,
	spawn(?MODULE, intersectionModelLoop,[Id, VertLightPid, HorLightPid, 1, 0, CounterPid,null,PrinterPID]).
	
intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, GreenTimer, CounterPid, ShifterPID, PrinterPID) ->
	GTm = if
		VertGreen =:= 0 -> if
												 (GreenTimer rem 4) =:= 0  -> CounterPid!{green} ;
												 true -> pass
											 end,
			1;
		true -> if
              GreenTimer =/= 0-> intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, 0, CounterPid, ShifterPID, PrinterPID);
              true -> pass
            end,
      0
	end,
	receive
		{shifter, PID}->
			CounterPid!{shifterPID,PID},
			intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, GreenTimer+GTm, CounterPid,PID, PrinterPID);

		newcarL->
			CounterPid!lcounter,
			intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, GreenTimer+GTm, CounterPid,ShifterPID, PrinterPID);

		newcarR->
			CounterPid!rcounter,
			intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, GreenTimer+GTm, CounterPid,ShifterPID, PrinterPID);

    togglelights ->
      case VertGreen of
        1 ->
          VertLightPid!{changecolor,toRed,HorLightPid,0,self()},
          intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, GreenTimer+GTm, CounterPid,ShifterPID, PrinterPID);
        0 ->
          HorLightPid!{changecolor,toRed,VertLightPid,1,self()},
          intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, GreenTimer+GTm, CounterPid,ShifterPID, PrinterPID)
      end;
		{vertGreen, VG}->
			intersectionModelLoop(Id, VertLightPid, HorLightPid, VG, GreenTimer+GTm, CounterPid,ShifterPID, PrinterPID);

		setred ->
			case VertGreen of
				1 ->
					%VertLightPid!{changecolor,toRed,HorLightPid,0,self()},
					intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, GreenTimer+GTm, CounterPid,ShifterPID,PrinterPID);
				0 ->
					HorLightPid!{changecolor,toRed,VertLightPid,1,self()},
					intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, GreenTimer+GTm, CounterPid,ShifterPID,PrinterPID)
			end;

    printlights ->
      VertLightPid!print,
      HorLightPid!print,
      intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, GreenTimer+GTm, CounterPid,ShifterPID, PrinterPID);
		quit ->
			VertLightPid!quit,
			HorLightPid!quit,
			CounterPid!quit,
			ShifterPID!quit

	after 100 -> intersectionModelLoop(Id, VertLightPid, HorLightPid, VertGreen, GreenTimer+GTm, CounterPid,ShifterPID, PrinterPID)
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

printer()->
	receive
		{drawGUI}->drawGUI(),
			printer();
		{gotoxy,X,Y}->print({gotoxy,X,Y}),
			printer();
		{print,Parameter}->print({Parameter}),
			printer();
		{printxy,X,Y,Msg}->printxy({X,Y,Msg}),
			printer();
		{printLightPair,Id, X, Y, Color} ->printLightPair(Id, X, Y, Color),
			printer();
		quit -> ok
	end.

logPrinter(Path)->
	{{Year,Month,Day},{Hour,Min,Sec}} = erlang:localtime(),
	Date = io_lib:format("Symulacje rozpoczeto: ~2..0w:~2..0w:~2..0w  ~2..0w-~2..0w-~4..0w\n", [Hour, Min, Sec, Day, Month, Year]),
	receive
		{quit,L,R}->
			{{YearF,MonthF,DayF},{HourF,MinF,SecF}} = erlang:localtime(),
			DateF = io_lib:format("Symulacje zakonczono: ~2..0w:~2..0w:~2..0w  ~2..0w-~2..0w-~4..0w\n", [HourF, MinF, SecF, DayF, MonthF, YearF]),
			Duration = (to_timestamp({{YearF,MonthF,DayF},{HourF,MinF,SecF}})-to_timestamp({{Year,Month,Day},{Hour,Min,Sec}})),
			DaysD = Duration div 86400,
			HoursD = (Duration - DaysD*86400) div 3600,
			MinutesD = (Duration - DaysD*86400 - HoursD*3600) div 60,
			SecondsD = (Duration - DaysD*86400 - HoursD*3600 - MinutesD*60),
			DurationP = io_lib:format("Symulacja trwala: ~w dni, ~w godzin, ~w minut, ~w sekund\n", [DaysD, HoursD, MinutesD, SecondsD]),
			CountL = io_lib:format("Na lewym skrzyzowaniu wygenerowano: ~w samochodow\n", [L]),
			CountR = io_lib:format("Na prawym skrzyzowaniu wygenerowano: ~w samochodow\n", [R]),
			file:write_file(Path, Date++CountL++CountR++DurationP++DateF++"\n-----------------------------------------------------\n",[append])
	end.


to_timestamp({{Year,Month,Day},{Hours,Minutes,Seconds}}) ->
	(calendar:datetime_to_gregorian_seconds(
		{{Year,Month,Day},{Hours,Minutes,Seconds}}
	) - 62167219200).



main() ->
	LogPrinterPID = spawn(?MODULE, logPrinter,["logRegister.txt"]),
	PrinterPID = spawn(?MODULE, printer,[]),
  PrinterPID!{drawGUI},
	PrinterPID!{print,hideCursor},
	ListenerPID = spawn(?MODULE, keyboardListener, [self(),PrinterPID]),
  IntersectionPids = [intersectionModelInit(N,PrinterPID) || N<-[0,1,2]],
	Shifter = spawn(?MODULE,shifter,[IntersectionPids]),
	lists:map(fun(Z) -> Z!{shifter,Shifter}, Z end, IntersectionPids),
	main(1, ListenerPID, IntersectionPids, 1,PrinterPID,0,0,LogPrinterPID).

% Mode = 1 -> zielona fala w prawo, -1 -> w lewo
main(Mode, ListenerPID, IntersectionPids, X,PrinterPID,LGen,RGen,LogPrinterPID) ->
	[FirstInter, MiddleInter, LastInter] = IntersectionPids,
%%	if
%%		((X - 2*100) rem (23*100) =:= 0) or ((X - 2*100 - 19*100) rem (23*100) =:= 0) ->
%%			FirstInter!togglelights,
%%			LastInter!togglelights;
%%		((X - 2*100 - 350) rem (23*100) =:= 0) or ((X - 2*100 - 1400) rem (23*100) =:= 0)->
%%			MiddleInter!togglelights;
%%		true -> ok
%%	end,

%%	case Mode of
%%      0 ->
%%        FirstChanging = FirstInter,
%%        LastChanging = LastInter,
%%        ProbL = 130,
%%        ProbR = 130;
%%		  1 ->
%%				FirstChanging = FirstInter,
%%				LastChanging = LastInter,
%%				ProbL = 100,
%%				ProbR = 180;
%%			-1 ->
%%				FirstChanging = LastInter,
%%				LastChanging = FirstInter,
%%				ProbL = 180,
%%				ProbR = 100
%%	end,

  if
      Mode =:= 0 ->
        if
          ((X - 2*100) >= 0) and (((X - 2*100) rem (23*100) =:= 0) or ((X - 2*100 - 19*100) rem (23*100) =:= 0)) ->
            FirstInter!togglelights,
            LastInter!togglelights;
          ((X - 2*100 - 350) >= 0) and (((X - 2*100 - 350) rem (23*100) =:= 0) or ((X - 2*100 - 1400) rem (23*100) =:= 0))->
            MiddleInter!togglelights;
          true -> ok
        end,
        ProbL = 130,
        ProbR = 130;
      true ->
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
        end
  end,

	L = rand:uniform(ProbL),
	R= rand:uniform(ProbR),
	GL = if
		L < 2 -> FirstInter!newcarL,
			1;
		true -> 0
	end,
	GR = if
		R < 2 -> LastInter!newcarR,
			1;
		true -> 0
	end,

  gotoend(),
  receive
		{ListenerPID, "q"} ->
			lists:map(fun(Z) -> Z!quit, Z end, IntersectionPids),
			LogPrinterPID!{quit,LGen+GL,RGen+GR},
			timer:sleep(1000),
			PrinterPID!{print,clear},
			PrinterPID!{gotoxy,1,1},
			PrinterPID!{print,showCursor},
			PrinterPID!quit,
			ok;
		{ListenerPID, "t"} ->
			FirstInter!setred,
			MiddleInter!setred,
			LastInter!setred,
			%timer:sleep(500),
			case Mode of
        1 ->   PrinterPID!{printxy,47,16, "<->"}, main(0, ListenerPID, IntersectionPids, -100,PrinterPID,LGen+GL,RGen+GR,LogPrinterPID);
        0 ->   PrinterPID!{printxy,47,16, "<--"}, main(-1, ListenerPID, IntersectionPids, -100,PrinterPID,LGen+GL,RGen+GR,LogPrinterPID);
        -1 ->   PrinterPID!{printxy,47,16, "-->"}, main(1, ListenerPID, IntersectionPids, -100,PrinterPID,LGen+GL,RGen+GR,LogPrinterPID)
			end
	after 10 ->
		main(Mode, ListenerPID, IntersectionPids, X+1,PrinterPID,LGen+GL,RGen+GR,LogPrinterPID)
	end.