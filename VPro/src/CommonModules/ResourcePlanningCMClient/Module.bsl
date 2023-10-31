Function GetMonthByNumber(MonthNumber, WithoutDeclension = False) Export
	
	MapMonth = New Map();
	
	If WithoutDeclension Then
		
		MapMonth.Insert(1, NStr("en='January';vi='Tháng 1';"));
		MapMonth.Insert(2, NStr("en='February';vi='Tháng 2';"));
		MapMonth.Insert(3, NStr("en='March';vi='Tháng 3';"));
		MapMonth.Insert(4, NStr("en='April';vi='Tháng 4';"));
		MapMonth.Insert(5, NStr("en='May';vi='Tháng 5';"));
		MapMonth.Insert(6, NStr("en='June';vi='Tháng 6';"));
		MapMonth.Insert(7, NStr("en='July';vi='Tháng 7';"));
		MapMonth.Insert(8, NStr("en='August';vi='Tháng 8';"));
		MapMonth.Insert(9, NStr("en='September';vi='Tháng 9';"));
		MapMonth.Insert(10, NStr("en='October';vi='Tháng 10';"));
		MapMonth.Insert(11, NStr("en='November';vi='Tháng 11';"));
		MapMonth.Insert(12, NStr("en='December';vi='Tháng 12';"));
		
	Else
		
		MapMonth.Insert(1, NStr("en='January';vi='Tháng 1';"));
		MapMonth.Insert(2, NStr("en='February';vi='Tháng 2';"));
		MapMonth.Insert(3, NStr("en='March';vi='Tháng 3';"));
		MapMonth.Insert(4, NStr("en='April';vi='Tháng 4';"));
		MapMonth.Insert(5, NStr("en='May';vi='Tháng 5';"));
		MapMonth.Insert(6, NStr("en='June';vi='Tháng 6';"));
		MapMonth.Insert(7, NStr("en='July';vi='Tháng 7';"));
		MapMonth.Insert(8, NStr("en='August';vi='Tháng 8';"));
		MapMonth.Insert(9, NStr("en='September';vi='Tháng 9';"));
		MapMonth.Insert(10, NStr("en='October';vi='Tháng 10';"));
		MapMonth.Insert(11, NStr("en='November';vi='Tháng 11';"));
		MapMonth.Insert(12, NStr("en='December';vi='Tháng 12';"));
		
	EndIf;
	
	Return MapMonth.Get(MonthNumber);
	
EndFunction

Function DescriptionWeekDays(CurrentData) Export
	
	PresentationRow = "";
	
	If CurrentData.Mon Then PresentationRow =  Nstr("en = 'Mon,'; ru = 'Пн,'; vi = 'T2,'") EndIf;
	If CurrentData.Tu Then PresentationRow = PresentationRow + Nstr("en = 'Tu,'; ru = 'Вт,'; vi = 'T3,'") EndIf;
	If CurrentData.We Then PresentationRow = PresentationRow + Nstr("en = 'We,'; ru = 'Ср,'; vi = 'T4,'") EndIf;
	If CurrentData.Th Then PresentationRow = PresentationRow + Nstr("en = 'Th,'; ru = 'Чт,'; vi = 'T5,'") EndIf;
	If CurrentData.Fr Then PresentationRow = PresentationRow + Nstr("en = 'Fr,'; ru = 'Пт,'; vi = 'T6,'") EndIf;
	If CurrentData.Sa Then PresentationRow = PresentationRow + Nstr("en = 'Sa,'; ru = 'Сб,'; vi = 'T7,'") EndIf;
	If CurrentData.Su Then PresentationRow = PresentationRow + Nstr("en = 'Su,'; ru = 'Вс,'; vi = 'CN,'") EndIf;
	
	If StrEndsWith(PresentationRow, " ,") Then
		StringLength = StrLen(PresentationRow);
		PresentationRow = " In "+Left(PresentationRow,StringLength - 2);
		PresentationRow = PresentationRow;
	EndIf;
	
	Return PresentationRow;
	
EndFunction

Function ItLastMonthWeek(WeekDate) Export
	
	MonthWeekDays = Month(WeekDate);
	
	If Not MonthWeekDays = Month(EndOfWeek(WeekDate)) 
		Or Not MonthWeekDays = Month(EndOfWeek(WeekDate+10)) Then
		Return True
	EndIf;
	
	Return False;
	
EndFunction

Function CountingItem(Number, CountingItemParameters1, CountingItemParameters2, CountingItemParameters3, Gender) Export
	
	FormatString = "L = ru_RU";
	
	MeasurementUnitInWordParameters = "%1,%2,%3,%4,,,,,0";
	MeasurementUnitInWordParameters = StrTemplate(
		MeasurementUnitInWordParameters,
		CountingItemParameters1,
		CountingItemParameters2,
		CountingItemParameters3,
		Gender);
		
	NumberStringAndCountingItem = Lower(NumberInWords(Number, FormatString, MeasurementUnitInWordParameters));
	
	NumberInWords = NumberStringAndCountingItem;
	NumberInWords = StrReplace(NumberInWords, CountingItemParameters1, "");
	NumberInWords = StrReplace(NumberInWords, CountingItemParameters2, "");
		
	CountingItem = StrReplace(NumberStringAndCountingItem, NumberInWords, "");
	
	Return CountingItem;
	
EndFunction

Function MapNumberWeekDay(DayNumber) Export
	
	ConformityOfReturn = New Map;
	
	ConformityOfReturn.Insert(1,"Monday");
	ConformityOfReturn.Insert(2,"Tuesday");
	ConformityOfReturn.Insert(3,"Wednesday");
	ConformityOfReturn.Insert(4,"Thursday");
	ConformityOfReturn.Insert(5,"Friday");
	ConformityOfReturn.Insert(6,"Saturday");
	ConformityOfReturn.Insert(7,"Sunday");
	
	Return ConformityOfReturn.Get(DayNumber);
	
EndFunction

Procedure FillDurationInSelectedResourcesTable(EnterpriseResources) Export
	
	For Each TableRow In EnterpriseResources Do
		
		EndOfPeriod = ?(TableRow.Finish = EndOfDay(TableRow.Finish), TableRow.Finish +1, TableRow.Finish);
		DurationInMinutes = (EndOfPeriod - TableRow.Start)/60;
		
		TableRow.Days = 0;
		
		If DurationInMinutes >= 1440 Then
			TableRow.Days = Int(DurationInMinutes/1440);
		EndIf;
		
		TableRow.Time = Date(1,1,1)+((DurationInMinutes - TableRow.Days*1440)*60);

	EndDo;
	
EndProcedure

//Очищает данные строки ресурсов
//
Procedure CleanRowData(CurrentData, CleanDate = True) Export
	
	CurrentData.WeekMonthNumber = 0;
	CurrentData.MonthNumber = 0;
	CurrentData.RepeatabilityDate = 0;
	CurrentData.WeekDayMonth = 0;
	CurrentData.LastMonthDay = False;

	CurrentData.CompleteKind = Undefined;
	CurrentData.CompleteAfter = Undefined;
	
	CurrentData.RepeatInterval = 0;
	CurrentData.RepeatKind = Nstr("en='Not repeat';ru='Не повторять';vi='Không lặp lại'");
	CurrentData.DetailsCounter = "";
	
	CurrentData.Mon = False;
	CurrentData.Tu = False;
	CurrentData.We = False;
	CurrentData.Th = False;
	CurrentData.Fr = False;
	CurrentData.Sa = False;
	CurrentData.Su = False;
	
	If CleanDate Then
		CurrentData.Days = 0;
		CurrentData.Time = Date(1,1,1);
		CurrentData.Start = Date(1,1,1);
		CurrentData.Finish = Date(1,1,1);
	EndIf;
	
EndProcedure

Procedure CheckPlanningStep(CurrentData, ItBeginDate = False, ChangedTime = False) Export
	
	MultiplicityPlanning = CurrentData.MultiplicityPlanning;
	
	EndOfPeriod = CurrentData.Finish;
	BeginOfPeriod = CurrentData.Start;
	
	EndOfPeriod = ?(EndOfPeriod = EndOfDay(EndOfPeriod), EndOfPeriod +1, EndOfPeriod);
	
	If CurrentData.ControlStep And ValueIsFilled(MultiplicityPlanning) Then
		
		Datediff = EndOfPeriod - BeginOfPeriod;
		
		MultiplicityPlanningSec = MultiplicityPlanning*60;
		QuantityEntryMultiplicitiInInterval = Round(Datediff/MultiplicityPlanningSec,0, RoundMode.Round15as20);
		
		If ItBeginDate Then
			BeginOfPeriod = EndOfPeriod - ?(QuantityEntryMultiplicitiInInterval <= 0,1,QuantityEntryMultiplicitiInInterval) * MultiplicityPlanningSec;
		Else
			EndOfPeriod = BeginOfPeriod + ?(QuantityEntryMultiplicitiInInterval <= 0,1,QuantityEntryMultiplicitiInInterval) * MultiplicityPlanningSec;
		EndIf;
		
		DurationInMinutes = (EndOfPeriod - BeginOfPeriod)/60;
		
		CurrentData.Days = 0;
		CurrentData.Time = 0;
		
		If DurationInMinutes >= 1440 Then
			CurrentData.Days = Int(DurationInMinutes/1440);
		EndIf;
		
		CurrentData.Time = Date(1,1,1)+((DurationInMinutes - CurrentData.Days*1440)*60);
		
		CurrentData.Finish = EndOfPeriod;
		CurrentData.Start = BeginOfPeriod;
		
	Else
		
		DurationInMinutes = (EndOfPeriod - BeginOfPeriod)/60;
		
		If Not ChangedTime Then
			DurationInMinutes = (EndOfPeriod - BeginOfPeriod)/60;
			
			CurrentData.Days = 0;
			CurrentData.Time = 0;
			
			If DurationInMinutes >= 1440 Then
				CurrentData.Days = Int(DurationInMinutes/1440);
			EndIf;
			
			CurrentData.Time = Date(1,1,1)+((DurationInMinutes - CurrentData.Days*1440)*60);
		EndIf;
		
	EndIf;
	
	CurrentData.Finish = ?(BegOfDay(CurrentData.Finish)> BegOfDay(CurrentData.Start) And CurrentData.Finish = BegOfDay(CurrentData.Finish), CurrentData.Finish - 1, CurrentData.Finish);
	
EndProcedure
