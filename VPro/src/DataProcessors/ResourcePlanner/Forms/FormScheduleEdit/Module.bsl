
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Repeatability = Parameters.Repeatability;
	
	FillResourcesFormParametersFromStructure(Parameters.StructureRepeat);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Repeatability = PredefinedValue("Enum.ScheduleRepeatKind.NoRepeat") Or Not ValueIsFilled(Repeatability) Then
		Repeatability = PredefinedValue("Enum.ScheduleRepeatKind.Daily");
	EndIf;
	
PerfomActionsMultiplicityOnChange();
EndProcedure

&AtClient
Procedure ExecuteAction(Command)
	
	If Repeatability = PredefinedValue("Enum.ScheduleRepeatKind.Weekly") And Not WeekDaySelected() Then
		
		Message = New UserMessage();
		Message.Text = NStr("en='Need to choice week day.';ru='Необходимо выбрать день недели.';vi='Cần chọn ngày trong tuần.'");
		Message.SetData(ThisForm);
		Message.Message();
		
		Return;
	EndIf;
	
	StructureClosingResult = ResultStructure();
	ThisForm.Close(StructureClosingResult);
	
EndProcedure

&AtClient
Procedure RepeatabilityOnChange(Item)
	PerfomActionsMultiplicityOnChange()
EndProcedure

&AtClient
Procedure RepeatIntervalTuning(Item, Direction, StandardProcessing)
	If RepeatInterval = 0 Then RepeatInterval = 1 EndIf;
EndProcedure

&AtClient
Procedure RepeatIntervalOnChange(Item)
	If RepeatInterval = 0 Then RepeatInterval = 1 EndIf;
EndProcedure

&AtClient
Procedure RepeatKindRepresentationOnChange(Item)
	
	If Repeatability = PredefinedValue("Enum.ScheduleRepeatKind.Annually") Then
		If Not ValueIsFilled(MonthNumber) Then MonthNumber = Month(ResourceDate) EndIf;
		
		Items.RepeatKindRepresentation.ChoiceList.Clear();
		
		Items.RepeatKindRepresentation.ChoiceList.Add("Number",String(CurDateRow)+Nstr("ru=' -ого';vi=' -'")+ GetMonthByNumber(MonthNumber)+"." );
		RepeatKindRepresentation = Items.RepeatKindRepresentation.ChoiceList[0].Presentation;
		RepeatabilityDate = CurDateRow;
		
		Return 
	EndIf;
	
	ListElement = Items.RepeatKindRepresentation.ChoiceList.FindByValue(RepeatKindRepresentation);
	RepeatKindRepresentation = ListElement.Presentation;
	
	RepeatabilityDate = 0;
	CurWeekday = 0;
	LastMonthDay = False;
	
	If ListElement.Value = "Number" Then
		RepeatabilityDate = CurDateRow;
	ElsIf ListElement.Value = "WeekDay" Then
		CurWeekday = CurWeekDayRows;
	ElsIf ListElement.Value = "LastDay" Then
		LastMonthDay = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure CloseForm(Command)
	ThisForm.Close();
EndProcedure

&AtClient
Function ResultStructure()
	
	StructureClosingResult = New Structure("RepeatKind, RepeatInterval, Mon, Tu, We, Th, Fr, Sa, Su, LastMonthDay, RepeatabilityDate, WeekDayMonth, WeekMonthNumber, MonthNumber"
												,Repeatability, RepeatInterval, Mon, Tu, We, Th, Fr, Sa, Su, LastMonthDay, RepeatabilityDate, CurWeekday, WeekMonthNumber, MonthNumber);

	Return StructureClosingResult;
	
EndFunction

&AtServer
Procedure FillResourcesFormParametersFromStructure(StructureRepeat)
	
	Mon = StructureRepeat.Mon;
	Tu = StructureRepeat.Tu;
	We = StructureRepeat.We;
	Th = StructureRepeat.Th;
	Fr = StructureRepeat.Fr;
	Sa = StructureRepeat.Sa;
	Su = StructureRepeat.Su;
	
	
	CurDateRow = StructureRepeat.StringDate;
	RepeatabilityDate = StructureRepeat.RepeatabilityDate;
	ResourceDate = StructureRepeat.PeriodRows;
	
	CurWeekday = StructureRepeat.WeekDayMonth;
	CurWeekDayRows = StructureRepeat.CurWeekday;
	WeekMonthNumber = StructureRepeat.WeekMonthNumber;
	
	LastMonthDay = StructureRepeat.LastMonthDay;
	
	RepeatInterval = StructureRepeat.RepeatInterval;

EndProcedure

&AtClient
Procedure PerfomActionsMultiplicityOnChange()
	
	Items.RepeatKindRepresentation.ChoiceList.Clear();
	
	If Not ValueIsFilled(Repeatability) Then 
		Repeatability = PredefinedValue("Enum.ScheduleRepeatKind.НеПовторять");
	EndIf;
	
	Repeat = ?(Repeatability = PredefinedValue("Enum.ScheduleRepeatKind.NoRepeat"), False, True);
	
	Items.Decoration2.Visible = Repeat;
	Items.Decoration3.Visible = Repeat;
	Items.RepeatInterval.Visible = Repeat;
	Items.WeekDaysGroup.Visible = Repeat;
	
	Items.GroupRepeatKind.Visible = False;
	
	If Repeatability = PredefinedValue("Enum.ScheduleRepeatKind.Monthly") 
		Or Repeatability = PredefinedValue("Enum.ScheduleRepeatKind.Annually") Then
	
		Items.WeekDaysGroup.Visible = False;
		Items.GroupRepeatKind.Visible = True;
		
		If Repeatability = PredefinedValue("Enum.ScheduleRepeatKind.Monthly") Then
			
			Items.RepeatKindRepresentation.ChoiceList.Add("Number",String(CurDateRow)+ Nstr("en='numbers.';ru='-ого числа';vi='-'"));
			
			If Not EndOfMonth(ResourceDate) = EndOfDay(ResourceDate) Then
				
				SchedulePresentation = MapNumberWeekDay(CurWeekDayRows);
				
				If ItLastMonthWeek(ResourceDate) Then
					SchedulePresentation =  NStr("en='In last ';ru='В конце ';vi='Cuối cùng'") + SchedulePresentation;
				Else
					
					WeekMonthNumber = WeekOfYear(ResourceDate)-WeekOfYear(BegOfMonth(ResourceDate))+1;
					
					SchedulePresentation = SchedulePresentation + Nstr("en=' every.';ru='каждую.';vi=' hàng.'") +String(WeekMonthNumber)+  Nstr("en = ''; ru = '-ую") + Nstr("en=' Weeks';ru='Неделю';vi=' Tuần'");
					
				EndIf;
				
				Items.RepeatKindRepresentation.ChoiceList.Add("WeekDay",SchedulePresentation);
				
			Else
				
				Items.RepeatKindRepresentation.ChoiceList.Add("LastDay",Nstr("en='In last day';ru='В последний день';vi='Vào ngày cuối cùng'"));
				
			EndIf;
			
			If ValueIsFilled(RepeatabilityDate) Then
				RepeatKindRepresentation = Items.RepeatKindRepresentation.ChoiceList[0].Presentation;
			ElsIf ValueIsFilled(CurWeekday) Then
				RepeatKindRepresentation = Items.RepeatKindRepresentation.ChoiceList[1].Presentation;
			ElsIf LastMonthDay = True Then
				RepeatKindRepresentation = Items.RepeatKindRepresentation.ChoiceList[1].Presentation;
			Else
				RepeatKindRepresentation = Items.RepeatKindRepresentation.ChoiceList[0].Presentation;
				RepeatabilityDate = CurDateRow;
			EndIf;
		Else
			
			If Not ValueIsFilled(MonthNumber) Then MonthNumber = Month(ResourceDate) EndIf;
			
			Items.RepeatKindRepresentation.ChoiceList.Add("Number",String(CurDateRow)+Nstr("en=' ';ru='-ого';vi='-'")+ GetMonthByNumber(MonthNumber)+"." );
			RepeatKindRepresentation = Items.RepeatKindRepresentation.ChoiceList[0].Presentation;
			RepeatabilityDate = CurDateRow;
		EndIf;
		
	Else
		
		RepeatabilityDate = 0;
		CurWeekday = 0;
		LastMonthDay = False;
		WeekMonthNumber = 0;
		MonthNumber = 0;
		
	EndIf;
	
	Items.RepeatKindRepresentation.DropListButton = True;
	
	If Repeatability = PredefinedValue("Enum.ScheduleRepeatKind.Daily") Then
		Items.Decoration2.Title = NStr("en='Each';ru='Каждый';vi='Mỗi'");
		Items.Decoration3.Title = NStr("en='Day';ru='День';vi='Ngày'");
		Items.WeekDaysGroup.Visible = False;
		RepeatabilityDate = 0;
		LastMonthDay = False;
		WeekDayMonth = False;
	ElsIf Repeatability = PredefinedValue("Enum.ScheduleRepeatKind.Weekly") Then
		Items.Decoration2.Title = NStr("en='Each';ru='Каждую';vi='Mỗi'");
		Items.Decoration3.Title = NStr("en='Week';ru='Неделю';vi='Tuần'"); 
		Items.WeekDaysGroup.Visible = True;
		RepeatabilityDate = 0;
		LastMonthDay = False;
		WeekDayMonth = False;
		SetupCurWeekDay();
	ElsIf Repeatability = PredefinedValue("Enum.ScheduleRepeatKind.Monthly") Then
		Items.Decoration2.Title = NStr("en='Each';ru='Каждый';vi='Mỗi'");
		Items.Decoration3.Title = NStr("en='Month';ru='Месяц';vi='Trong tháng tới'");
	ElsIf Repeatability = PredefinedValue("Enum.ScheduleRepeatKind.Annually") Then
		Items.Decoration2.Title = Nstr("en='Each';ru='Каждый';vi='Mỗi'");
		Items.Decoration3.Title = Nstr("en='Year';ru='Год';vi='Trong năm tới'");
		Items.RepeatKindRepresentation.DropListButton = False;
	EndIf;
	
	If RepeatInterval = 0 Then RepeatInterval = 1 EndIf;
	
	If Not Repeatability = PredefinedValue("Enum.ScheduleRepeatKind.Weekly") Then CleanWeekDays() EndIf;
	
EndProcedure

&AtClient
Function GetMonthByNumber(MonthNumber)
	
	MapMonth = New Map();
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
	
	Return MapMonth.Get(MonthNumber); 
	
EndFunction

&AtClient
Function ItLastMonthWeek(WeekDate)
	
	MonthWeekDays = Month(WeekDate);
	
	If Not MonthWeekDays = Month(EndOfWeek(WeekDate)) 
		Or Not MonthWeekDays = Month(EndOfWeek(WeekDate+10)) Then
		Return True
	EndIf;
	
	Return False;
	
EndFunction

&AtClient
Function MapNumberWeekDay(DayNumber)
	
	ConformityOfReturn = New Map;
	
	ConformityOfReturn.Insert(1,NStr("en='Monday';vi='Thứ 2';"));
	ConformityOfReturn.Insert(2,NStr("en='Tuesday';vi='Thứ 3';"));
	ConformityOfReturn.Insert(3,NStr("en='Wednesday';vi='Thứ 4';"));
	ConformityOfReturn.Insert(4,NStr("en='Thursday';vi='Thứ 5';"));
	ConformityOfReturn.Insert(5,NStr("en='Friday';vi='Thứ 6';"));
	ConformityOfReturn.Insert(6,NStr("en='Saturday';vi='Thứ 7';"));
	ConformityOfReturn.Insert(7,NStr("en='Sunday';vi='Chủ nhật';"));
	
	Return ConformityOfReturn.Get(DayNumber);
	
EndFunction

&AtClient
Procedure SetupCurWeekDay()
	
	If Not WeekDaySelected() Then
		
		DayNumber = ?(ValueIsFilled(ResourceDate), WeekDay(ResourceDate), WeekDay(CurrentDate()));
		
		If DayNumber = 1 Then Mon = True
		ElsIf DayNumber = 2 Then Tu = True
		ElsIf DayNumber = 3 Then We = True
		ElsIf DayNumber = 4 Then Th = True
		ElsIf DayNumber = 5 Then Fr = True
		ElsIf DayNumber = 6 Then Sa = True
		ElsIf DayNumber = 7 Then Su = True
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Function WeekDaySelected()
	
	If Not Mon And Not Tu And Not We And Not Th And Not Fr And Not Sa And Not Su Then
		Return False
	EndIf;
	
	Return True;
	
EndFunction

&AtClient
Procedure CleanWeekDays()
	Mon = False;
	Tu = False;
	We = False;
	Th = False;
	Fr = False;
	Sa = False;
	Su = False;
EndProcedure

