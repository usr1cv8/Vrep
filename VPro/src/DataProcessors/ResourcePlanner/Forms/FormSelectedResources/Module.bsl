&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ResourcesTable = New ValueTable;
	ResourcesTable = Parameters.SelectedResources.Unload();
	ResourcesTable.GroupBy("Resource, BeginOfPeriod, EndOfPeriod, RepeatKind, Mon, Tu, We, Th, Fr, Sa, Su
							|, RepeatInterval, CompleteAfter, CompleteKind, Time, RepeatabilityDate, LastMonthDay
							|, WeekDayMonth,WeekMonthNumber, ControlStep, MultiplicityPlanning","Loading");
	
	For Each RowResource In ResourcesTable Do 
		
		NewRow = SelectedResources.Add();
		FillPropertyValues(NewRow, RowResource);
		
	EndDo;
	
	FillDurationInSelectedResourcesTable();
	ResourcePlanningCM.SetupConditionalAppearanceResources("SelectedResources", ThisObject);
	
	ThisSelection = Parameters.Property("ThisSelection") And Parameters.ThisSelection;
	
	If ThisSelection Then
		Items.GroupSubmenu.Visible = False;
		Items.TransferToDocument.Visible = True;
	Else
		
		Items.CreateProductionOrder.Visible = Parameters.OnlyBySubsystem2;
		Items.AddInProductionOrder.Visible = Parameters.OnlyBySubsystem2;
		
		Items.CreateEvent.Visible = Parameters.OnlyBySubsystem3;
		Items.AddInEvent.Visible = Parameters.OnlyBySubsystem3;
		
		Items.CreateWorkOrder.Visible = Parameters.OnlyBySubsystem1;
		Items.AddInWorkOrder.Visible = Parameters.OnlyBySubsystem1;
		Items.TransferToDocument.Visible = False;
		
		Items.GroupSubmenu.Enabled = SelectedResources.Count();
		
	EndIf;
	
	CurrentDate = CurrentSessionDate();
	Counterparty = Parameters.Counterparty;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SetupRepeatAvailable(True);
	CreateScheduleDescription();
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not ClosingwithCommand Then
		
		If AreFillingErrors() Then Return EndIf;
		
		StandardProcessing = False;
		StructureClosingParameters = New Structure("SelectedResources", SelectedResources);
		ThisForm.Close(StructureClosingParameters);
	EndIf;

EndProcedure

&AtClient
Procedure CreateWorkOrder(Command)
	
	FillingValues = New Structure("OperationKind, Counterparty", PredefinedValue("Enum.OperationKindsCustomerOrder.WorkOrder"), Counterparty);
	
	OpenParameters = New Structure("SelectedResources, FillingValues",SelectedResources, FillingValues);
	OpenForm("Document.CustomerOrder.Form.FormWorkOrder", OpenParameters, ThisForm);

	SelectedResources.Clear();
	StructureClosingParameters = New Structure("SelectedResources", SelectedResources);
	ThisForm.Close(StructureClosingParameters);
EndProcedure

&AtClient
Procedure CreateProductionOrder(Command)
	
	OpenParameters = New Structure("SelectedResources, OpenFormPlanner",SelectedResources, True);
	OpenForm("Document.ProductionOrder.ObjectForm", OpenParameters, ThisForm);

	SelectedResources.Clear();
	StructureClosingParameters = New Structure("SelectedResources", SelectedResources);
	ThisForm.Close(StructureClosingParameters);
	
EndProcedure

&AtClient
Procedure AddInProductionOrder(Command)
	OpenParameters = New Structure();
	OpenForm("Document.ProductionOrder.Form.ChoiceForm", OpenParameters,ThisForm);
EndProcedure

&AtClient
Procedure AddInWorkOrder(Command)
	OpenParameters = New Structure("ChoiceMode",True);
	OpenForm("Document.CustomerOrder.Form.ListFormWorkOrder", OpenParameters, ThisForm);
EndProcedure

&AtClient
Procedure CleanBin(Command)
	ClosingwithCommand = True;
	SelectedResources.Clear();
	StructureClosingParameters = New Structure("SelectedResources", SelectedResources);
	ThisForm.Close(StructureClosingParameters);
EndProcedure

&AtClient
Procedure CloseForm(Command)
	
	If AreFillingErrors() Then Return EndIf;
	
	ClosingwithCommand = True;
	
	StructureClosingParameters = New Structure("SelectedResources", SelectedResources);
	ThisForm.Close(StructureClosingParameters);
	
EndProcedure

&AtClient
Procedure CreateEvent(Command)
	OpenParameters = New Structure("SelectedResources, OpenFormPlanner",SelectedResources, True);
	OpenForm("Document.Event.Form.FormEventCounterpartyRecord", OpenParameters, ThisForm);
	
	SelectedResources.Clear();
	StructureClosingParameters = New Structure("SelectedResources", SelectedResources);
	ThisForm.Close(StructureClosingParameters);
EndProcedure

&AtClient
Procedure AddInEvent(Command)
	OpenParameters = New Structure("ChoiceMode, EventType", True, PredefinedValue("Enum.EventTypes.Record"));
	OpenForm("Document.Event.ListForm", OpenParameters, ThisForm);
EndProcedure

&AtClient
Procedure Control(Command)
	ControlAtServer();
EndProcedure

&AtClient
Procedure TransferToDocument(Command)
	
	ClosingwithCommand = True;
	
	StructureClosingParameters = New Structure("SelectedResources, CloseForm", SelectedResources, True);
	ThisForm.Close(StructureClosingParameters);
	
EndProcedure

&AtClient
Procedure SelectedResourcesOnChange(Item)
	
	For Each TableRow In SelectedResources Do
		TableRow.SchedulePresentation = ?(TableRow.SchedulePresentation = "", Nstr("en='Not repeat';ru='Не повторять';vi='Không lặp lại'"), TableRow.SchedulePresentation);
	EndDo;
	
	SetupRepeatAvailable();
	Items.GroupSubmenu.Enabled = SelectedResources.Count();
	
EndProcedure

&AtClient
Procedure SelectedResourcesCompleteKindOnChange(Item)
	
	CurrentData = Items.SelectedResources.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	If CurrentData.CompleteKind = PredefinedValue("Enum.ScheduleRepeatCompletingKind.AtDate") Then
		CurrentData.CompleteAfter = CurrentData.EndOfPeriod;
		CurrentData.DetailsCounter = "";
	ElsIf CurrentData.CompleteKind = PredefinedValue("Enum.ScheduleRepeatCompletingKind.ByCounter") Then
		CurrentData.CompleteAfter = 1;
		CurrentData.DetailsCounter = "Time";
	Else
		CurrentData.DetailsCounter = "";
		CurrentData.CompleteAfter = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectedResoucesFinishPeriodOnChange(Item)
	OnChangePeriod()
EndProcedure

&AtClient
Procedure SelectedResoucesFinishPeriodTimeOnChange(Item)
	OnChangePeriod();
EndProcedure

&AtClient
Procedure SelectedResourcesCompleteAfterOnChange(Item)
	
	CurrentData = Items.SelectedResources.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	If CurrentData.CompleteKind = PredefinedValue("Enum.ScheduleRepeatCompletingKind.ByCounter")
		And ValueIsFilled(CurrentData.CompleteAfter) Then 
		
		DetailsCounter = CountingItem(
		CurrentData.CompleteAfter,
		NStr("en='раза';ru='раза';vi='lần'"),
		NStr("en='раз';ru='раз';vi='lần'"),
		NStr("en='раз';ru='раз';vi='lần'"),
		"M");
		
		CurrentData.DetailsCounter = DetailsCounter;
	Else
		CurrentData.DetailsCounter = "";
	EndIf;
	
	If TypeOf(CurrentData.CompleteAfter) = Type("Date")
		And ValueIsFilled(CurrentData.CompleteAfter)
		And ValueIsFilled(CurrentData.BeginOfPeriod)
		And CurrentData.CompleteAfter<BegOfDay(CurrentData.BeginOfPeriod)
		Then
		CurrentData.CompleteAfter=BegOfDay(CurrentData.BeginOfPeriod)
	EndIf;
	
 EndProcedure

&AtClient
Procedure SelectedResourcesDaysOnChange(Item)
	SpecifiedEndOfPeriod();
	SetupRepeatAvailable();
EndProcedure

&AtClient
Procedure SelectedResourcesTimeOnChange(Item)
	SpecifiedEndOfPeriod();
	SetupRepeatAvailable();
EndProcedure

&AtClient
Procedure SelectedResourcesBeforeAddRow(Item, Cancel, Copy, Parent, Group, Parameter)
	Cancel = True;
EndProcedure

&AtClient
Procedure AfterEndScheduleEdit(ExecutionResult, Parameters) Export
	
	If ExecutionResult = Undefined Then Return EndIf;
	
	CurrentData = Items.SelectedResources.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	RepeatKind = ExecutionResult.RepeatKind;
	
	CurrentData.RepeatKind = RepeatKind;
	
	If RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.NoRepeat") Then
		 ResourcePlanningCMClient.CleanRowData(CurrentData, False);
		 CreateScheduleDescription();
		 Return;
	 EndIf;
	 
	CurrentData.RepeatInterval = ExecutionResult.RepeatInterval;
	CurrentData.Mon = ExecutionResult.Mon;
	CurrentData.Tu = ExecutionResult.Tu;
	CurrentData.We = ExecutionResult.We;
	CurrentData.Th = ExecutionResult.Th;
	CurrentData.Fr = ExecutionResult.Fr;
	CurrentData.Sa = ExecutionResult.Sa;
	CurrentData.Su = ExecutionResult.Su;
	CurrentData.LastMonthDay = ExecutionResult.LastMonthDay;
	CurrentData.RepeatabilityDate = ExecutionResult.RepeatabilityDate;
	CurrentData.WeekDayMonth = ExecutionResult.WeekDayMonth;
	CurrentData.WeekMonthNumber = ExecutionResult.WeekMonthNumber;
	CurrentData.MonthNumber = ExecutionResult.MonthNumber;
	
	CreateScheduleDescription();
	
EndProcedure

&AtClient
Procedure SelectedResoucesLoadingScheduleAutoComplete(Item, Text, ChoiceData, GetingDataParameters, Waiting, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.SelectedResources.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	StringDate = Day(CurrentData.BeginOfPeriod);
	
	NotificationParameters = New Structure;
	
	Notification = New NotifyDescription("AfterEndScheduleEdit", ThisObject, NotificationParameters);
	
	StructureRepeat = New Structure("RepeatInterval, Mon, Tu, We, Th, Fr, Sa, Su, LastMonthDay, RepeatabilityDate, WeekDayMonth, StringDate, CurWeekday, WeekMonthNumber, PeriodRows, MonthNumber"
										,CurrentData.RepeatInterval, CurrentData.Mon, CurrentData.Tu, CurrentData.We
										,CurrentData.Th,CurrentData.Fr, CurrentData.Sa, CurrentData.Su, CurrentData.LastMonthDay
										,CurrentData.RepeatabilityDate, CurrentData.WeekDayMonth, StringDate, WeekDay(CurrentData.BeginOfPeriod), CurrentData.WeekMonthNumber, CurrentData.BeginOfPeriod, CurrentData.MonthNumber);
	
	OpenParameters = New Structure("Repeatability, StructureRepeat", CurrentData.RepeatKind, StructureRepeat);
	
	OpenForm("DataProcessor.ResourcePlanner.Form.FormScheduleEdit",OpenParameters, ThisForm,,,,Notification, FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure SelectedResoucesBeginPeriodOnChange(Item)
	OnChangePeriod(True)
EndProcedure

&AtClient
Procedure SelectedResoucesBeginPeriodTimeOnChange(Item)
	OnChangePeriod(True)
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If Not SelectedValue = Undefined Then 
		If TypeOf(SelectedValue) = Type("DocumentRef.ProductionOrder") Then
			OpenParameters = New Structure("Key, SelectedResources, OpenFormPlanner",SelectedValue, SelectedResources, True);
			OpenForm("Document.ProductionOrder.ObjectForm", OpenParameters, ThisForm);
		EndIf;
		
		If TypeOf(SelectedValue) = Type("DocumentRef.CustomerOrder") Then
			OpenParameters = New Structure("Key, SelectedResources, OpenFormPlanner",SelectedValue, SelectedResources, True);
			OpenForm("Document.CustomerOrder.Form.FormWorkOrder", OpenParameters, ThisForm);
		EndIf;
		
		If TypeOf(SelectedValue) = Type("DocumentRef.Event") Then
			OpenParameters = New Structure("Key, SelectedResources, OpenFormPlanner",SelectedValue, SelectedResources, True);
			OpenForm("Document.Event.Form.FormEventCounterpartyRecord", OpenParameters, ThisForm);
		EndIf;
		
		SelectedResources.Clear();
		StructureClosingParameters = New Structure("SelectedResources", SelectedResources);
		ThisForm.Close(StructureClosingParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateScheduleDescription()
	
	For Each CurrentData In SelectedResources Do
		
		SelectedWeekDays = ResourcePlanningCMClient.DescriptionWeekDays(CurrentData);
		
		AddingByMonthYear = "";
		
		If CurrentData.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Monthly")
			Or CurrentData.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Annually") Then
			
			If ValueIsFilled(CurrentData.RepeatabilityDate) Then
				
				AddingByMonthYear = ?(ValueIsFilled(CurrentData.RepeatabilityDate), ", every " 
										+ String(CurrentData.RepeatabilityDate) + "-ok "+ResourcePlanningCMClient.GetMonthByNumber(CurrentData.MonthNumber)+".","");
			ElsIf ValueIsFilled(CurrentData.WeekDayMonth) Then
				
				If ResourcePlanningCMClient.ItLastMonthWeek(CurrentData.BeginOfPeriod) Then
					AddingByMonthYear = ", In last. " + ResourcePlanningCMClient.MapNumberWeekDay(CurrentData.WeekDayMonth)+ " month.";
				Else
				WeekMonthNumber = WeekOfYear(CurrentData.BeginOfPeriod)-WeekOfYear(BegOfMonth(CurrentData.BeginOfPeriod))+1;
				AddingByMonthYear = " "+ResourcePlanningCMClient.MapNumberWeekDay(CurrentData.WeekDayMonth) + " every. " +String(WeekMonthNumber)+ "-Iy" + " Weeks";
				EndIf;
				
			ElsIf CurrentData.LastMonthDay = True Then
				AddingByMonthYear = ", last day month.";
			EndIf;
			
		EndIf;
		
		Interjection = ?(CurrentData.RepeatKind = "Weekly","Every", "Each");
		
		End = "";
		
		If CurrentData.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Weekly") Then
			End = "Week"
		ElsIf CurrentData.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Daily") Then
			End = "Day"
		ElsIf CurrentData.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Monthly") Then
			End = "Month"
		ElsIf CurrentData.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Annually") Then
			End = "Year"
		EndIf;
		
		If Not CurrentData.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.NoRepeat")
			And ValueIsFilled(CurrentData.RepeatKind) Then
			SchedulePresentation = String(CurrentData.RepeatKind)+", "+Interjection+" "+String(CurrentData.RepeatInterval)+
			" "+ End+SelectedWeekDays+AddingByMonthYear;
		Else
			SchedulePresentation = Nstr("en='Not repeat';ru='Не повторять';vi='Không lặp lại'")
		EndIf;
		
		CurrentData.SchedulePresentation = SchedulePresentation;
	EndDo;

	
EndProcedure

&AtClient
Procedure SetupRepeatAvailable(FormOpening = False)
	
	If FormOpening Then
		
		For Each RowSelectedResourses In SelectedResources Do
			
			RowSelectedResourses.SchedulePresentation = ?(RowSelectedResourses.SchedulePresentation = "", Nstr("en='Not repeat';ru='Не повторять';vi='Không lặp lại'"), RowSelectedResourses.SchedulePresentation);
			
			If ValueIsFilled(RowSelectedResourses.BeginOfPeriod) And ValueIsFilled(RowSelectedResourses.EndOfPeriod) Then
				
				RowSelectedResourses.PeriodDifferent = ?(Not BegOfDay(RowSelectedResourses.BeginOfPeriod) = BegOfDay(RowSelectedResourses.EndOfPeriod), True, False);
				
				If BegOfDay(RowSelectedResourses.BeginOfPeriod) = BegOfDay(RowSelectedResourses.EndOfPeriod) Then
					RowSelectedResourses.RepeatsAvailable = True;
				EndIf;
				
			EndIf;
		EndDo;
		
		Return;
	EndIf;
	
	CurrentData = Items.SelectedResources.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	CurrentData.RepeatsAvailable = False;
	CurrentData.PeriodDifferent = False;
	
	If ValueIsFilled(CurrentData.BeginOfPeriod) And ValueIsFilled(CurrentData.EndOfPeriod) Then
		
		CurrentData.PeriodDifferent = ?(Not BegOfDay(CurrentData.BeginOfPeriod) = BegOfDay(CurrentData.EndOfPeriod), True, False);
		
		If BegOfDay(CurrentData.BeginOfPeriod) = BegOfDay(CurrentData.EndOfPeriod) Then
			CurrentData.RepeatsAvailable = True;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckPlanningStep(CurrentData, ItBeginDate = False, ChangedTime = False)
	
	MultiplicityPlanning = CurrentData.MultiplicityPlanning;
	
	EndOfPeriod = ?(CurrentData.EndOfPeriod = EndOfDay(CurrentData.EndOfPeriod), CurrentData.EndOfPeriod +1, CurrentData.EndOfPeriod);
	
	If CurrentData.ControlStep And ValueIsFilled(MultiplicityPlanning) Then
		
		Datediff = EndOfPeriod - CurrentData.BeginOfPeriod;
		
		MultiplicityPlanningSec = MultiplicityPlanning*60;
		QuantityEntryMultiplicitiInInterval = Round(Datediff/MultiplicityPlanningSec,0, RoundMode.Round15as20);
		
		If ItBeginDate Then
			CurrentData.BeginOfPeriod = EndOfPeriod - ?(QuantityEntryMultiplicitiInInterval <= 0,1,QuantityEntryMultiplicitiInInterval) * MultiplicityPlanningSec;
		Else
			CurrentData.EndOfPeriod = CurrentData.BeginOfPeriod + ?(QuantityEntryMultiplicitiInInterval <= 0,1,QuantityEntryMultiplicitiInInterval) * MultiplicityPlanningSec;
		EndIf;
		
		DurationInMinutes = (CurrentData.EndOfPeriod - CurrentData.BeginOfPeriod)/60;
		
		CurrentData.Days = 0;
		CurrentData.Time = 0;
		
		If DurationInMinutes >= 1440 Then
			CurrentData.Days = Int(DurationInMinutes/1440);
		EndIf;
		
		CurrentData.Time = Date(1,1,1)+((DurationInMinutes - CurrentData.Days*1440)*60);
		
	Else
		
		DurationInMinutes = (EndOfPeriod - CurrentData.BeginOfPeriod)/60;
		
		If Not ChangedTime Then
			
			CurrentData.Days = 0;
			CurrentData.Time = 0;
			
			If DurationInMinutes >= 1440 Then
				CurrentData.Days = Int(DurationInMinutes/1440);
			EndIf;
			
			CurrentData.Time = Date(1,1,1)+((DurationInMinutes - CurrentData.Days*1440)*60);
		EndIf;
		
	EndIf;
	
	CurrentData.EndOfPeriod = ?(BegOfDay(CurrentData.EndOfPeriod)> BegOfDay(CurrentData.BeginOfPeriod) And CurrentData.EndOfPeriod = BegOfDay(CurrentData.EndOfPeriod)
										, CurrentData.EndOfPeriod - 1, CurrentData.EndOfPeriod);
	
EndProcedure

&AtClient
Procedure OnChangePeriod(ItBeginDate = False)
	
	CurrentData = Items.SelectedResources.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	BalanceSecondToEndDay = EndOfDay(CurrentData.EndOfPeriod) - CurrentData.EndOfPeriod;
	
	If BalanceSecondToEndDay = 59 Then CurrentData.EndOfPeriod = EndOfDay(CurrentData.EndOfPeriod) EndIf;
	If CurrentData.EndOfPeriod = BegOfDay(CurrentData.EndOfPeriod) Then CurrentData.EndOfPeriod = CurrentData.EndOfPeriod-1 EndIf;
	
		CurrentData.BeginOfPeriod = ?(Minute(CurrentData.BeginOfPeriod)%5 = 0, CurrentData.BeginOfPeriod, CurrentData.BeginOfPeriod - (Minute(CurrentData.BeginOfPeriod)%5*60));
		
		If Not (Minute(CurrentData.EndOfPeriod)%5 = 0 Or CurrentData.EndOfPeriod = EndOfDay(CurrentData.EndOfPeriod)) Then
			CurrentData.EndOfPeriod = CurrentData.EndOfPeriod - (Minute(CurrentData.EndOfPeriod)%5*60);
		EndIf;
	
	If CurrentData.BeginOfPeriod > CurrentData.EndOfPeriod Then 
		
		If ItBeginDate Then 
			CurrentData.EndOfPeriod = CurrentData.BeginOfPeriod+CurrentData.MultiplicityPlanning*60;
		Else
			CurrentData.EndOfPeriod = CurrentData.BeginOfPeriod;
		EndIf;
		
	EndIf;
	
	CurrentData.BeginOfPeriod = ?(Second(CurrentData.BeginOfPeriod) = 0, CurrentData.BeginOfPeriod, CurrentData.BeginOfPeriod - Second(CurrentData.BeginOfPeriod));
	
	If Not (Second(CurrentData.EndOfPeriod) = 0 Or CurrentData.EndOfPeriod = EndOfDay(CurrentData.EndOfPeriod)) Then
		CurrentData.EndOfPeriod = CurrentData.EndOfPeriod - Second(CurrentData.EndOfPeriod)
	EndIf;
		
	CheckPlanningStep(CurrentData, ItBeginDate);
	
	SetupRepeatAvailable();
	
	If CurrentData.RepeatsAvailable Then
		
		If ValueIsFilled(CurrentData.RepeatabilityDate) Then
			CurrentData.RepeatabilityDate = Day(CurrentData.BeginOfPeriod);
		EndIf;
		
		If CurrentData.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Monthly") Then
			
			If ValueIsFilled(CurrentData.WeekDayMonth) Then
				
				If EndOfDay(CurrentData.BeginOfPeriod) = EndOfMonth(CurrentData.BeginOfPeriod) Then
					
					CurrentData.WeekDayMonth = 0;
					CurrentData.WeekMonthNumber = 0;
					CurrentData.LastMonthDay = True
					
				Else
					
					CurrentData.WeekDayMonth = WeekDay(CurrentData.BeginOfPeriod);
					
					CurWeekNumber = WeekOfYear(CurrentData.BeginOfPeriod)-WeekOfYear(BegOfMonth(CurrentData.BeginOfPeriod))+1;
					
					If ValueIsFilled(CurrentData.WeekMonthNumber) And Not CurrentData.WeekMonthNumber = CurWeekNumber  Then
						CurrentData.WeekMonthNumber = CurWeekNumber;
					EndIf;
					
				EndIf;
				
			EndIf;
			
			If CurrentData.LastMonthDay And Not EndOfDay(CurrentData.BeginOfPeriod) = EndOfMonth(CurrentData.BeginOfPeriod) Then
				
				CurrentData.LastMonthDay = False;
				CurrentData.WeekDayMonth = WeekDay(CurrentData.BeginOfPeriod);
			EndIf;
			
		EndIf;
		
		If CurrentData.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Annually")
			And ValueIsFilled(CurrentData.MonthNumber) Then
			
			CurrentData.MonthNumber = Month(CurrentData.BeginOfPeriod);
			
		EndIf;
		
	Else
		
		CurrentData.WeekMonthNumber = 0;
		CurrentData.MonthNumber = 0;
		CurrentData.RepeatabilityDate = 0;
		CurrentData.WeekDayMonth = 0;
		CurrentData.LastMonthDay = False;
		
		CurrentData.CompleteKind = Undefined;
		CurrentData.CompleteAfter = Undefined;
		
		CurrentData.RepeatInterval = 0;
		CurrentData.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.NoRepeat");
		CurrentData.DetailsCounter = "";
		
		CurrentData.Mon = False;
		CurrentData.Tu = False;
		CurrentData.We = False;
		CurrentData.Th = False;
		CurrentData.Fr = False;
		CurrentData.Sa = False;
		CurrentData.Su = False;
		
	EndIf;
	
	CreateScheduleDescription();
	
	If ItBeginDate Then
		If TypeOf(CurrentData.CompleteAfter) = Type("Date")
			And ValueIsFilled(CurrentData.CompleteAfter)
			And ValueIsFilled(CurrentData.BeginOfPeriod)
			And CurrentData.CompleteAfter<BegOfDay(CurrentData.BeginOfPeriod)
			Then
			CurrentData.CompleteAfter=BegOfDay(CurrentData.BeginOfPeriod)
		EndIf;
	EndIf
	
EndProcedure

&AtClient
Procedure SelectedResoucesFinishPeriodTimeTuning(Item, Direction, StandardProcessing)
	
	If Direction > 0 Then
		CurrentData = Items.SelectedResources.CurrentData;
		
		BalanceSecondToEndDay = EndOfDay(CurrentData.EndOfPeriod) - CurrentData.EndOfPeriod;
		
		If BalanceSecondToEndDay = 299 Then
			StandardProcessing = False;
			CurrentData.EndOfPeriod = EndOfDay(CurrentData.EndOfPeriod);
			OnChangePeriod();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillDurationInSelectedResourcesTable()
	
	For Each TableRow In SelectedResources Do
		
		EndOfPeriod = ?(TableRow.EndOfPeriod = EndOfDay(TableRow.EndOfPeriod), TableRow.EndOfPeriod +1, TableRow.EndOfPeriod);
		
		DurationInMinutes = (EndOfPeriod - TableRow.BeginOfPeriod)/60;
		
		TableRow.Days = 0;
		
		If DurationInMinutes >= 1440 Then
			TableRow.Days = Int(DurationInMinutes/1440);
		EndIf;
		
		TableRow.Time = Date(1,1,1)+((DurationInMinutes - TableRow.Days*1440)*60);
	EndDo;
	
EndProcedure

 &AtClient
 Function CountingItem(Number, CountingItemParameters1, CountingItemParameters2, CountingItemParameters3, Gender)
	
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

&AtClient
Procedure SpecifiedEndOfPeriod()
	
	CurrentData = Items.SelectedResources.CurrentData;
	If CurrentData = Undefined Then Return EndIf;
	
	SecondsOnTime = CurrentData.Time - Date(1,1,1);
	SeconrdOnDays = ?(ValueIsFilled(CurrentData.Days), CurrentData.Days*1440*60, 0);
	
	CurrentData.EndOfPeriod = CurrentData.BeginOfPeriod + SeconrdOnDays + SecondsOnTime;
	CurrentData.EndOfPeriod = ?(Not SeconrdOnDays = 0 And CurrentData.EndOfPeriod = BegOfDay(CurrentData.EndOfPeriod)
										, CurrentData.EndOfPeriod - 1, CurrentData.EndOfPeriod);
	
	CheckPlanningStep(CurrentData);
	
EndProcedure

&AtServer
Procedure ControlAtServer()
	
	If Not SelectedResources.Count() Then Return EndIf;
	
	If AreFillingErrors() Then Return EndIf;
	
	ResourcesTable = SelectedResources.Unload(,"Resource");
	ResourcesArray = ResourcesTable.UnloadColumn("Resource");
	ExtendedTable = DecomposeRowsBySchedule(SelectedResources);
	CheckingPeriod = ResourcePlanningCM.MaxIntervalBoarders(ExtendedTable, "BeginOfPeriod", "EndOfPeriod");
	ResourcesDataPacket = ResourcePlanningCM.GetResourcesWorkImportSchedule(ResourcesArray, CheckingPeriod.IntervalBegin, CheckingPeriod.IntervalEnd);
	
	ScheduleLoading = ResourcesDataPacket.ScheduleLoading;
	
	ResourcesTable = ExtendedTable.Copy(,"Resource, Period, BeginOfPeriod, EndOfPeriod, Loading");
	ResourcesTable.GroupBy("Resource, Period, BeginOfPeriod, EndOfPeriod", "Loading");
	ResourcesTable.Sort("BeginOfPeriod Asc");
	
	IntervalMatrix = ResourcePlanningCM.CreateIntervalColumns();
	
	For Each TableRow In ResourcesTable Do
		
		EndOfPeriod = ?(TableRow.EndOfPeriod = EndOfDay(TableRow.EndOfPeriod)
		, TableRow.EndOfPeriod + 1, TableRow.EndOfPeriod);
		
		MultiplicityPlanning = TableRow.Resource.MultiplicityPlanning;
		Capacity = TableRow.Resource.Capacity;
		
		FilterParameters = New Structure("EnterpriseResource, Period",TableRow.Resource,TableRow.Period);
		FoundStrings = ScheduleLoading.FindRows(FilterParameters);
		
		DocumentPerPeriod = ResourcePlanningCM.DocumentTablePerPeriod(FoundStrings, TableRow.BeginOfPeriod, EndOfPeriod, MultiplicityPlanning);
		
		CellsInIntervalQuantity = (EndOfPeriod - TableRow.BeginOfPeriod)/300;
		LoadingForInterval = ResourcePlanningCM.MaxByLoading(DocumentPerPeriod, TableRow.BeginOfPeriod, EndOfPeriod, CellsInIntervalQuantity, IntervalMatrix);
		
		HasErrors = False;
		
		If (LoadingForInterval+TableRow.Loading)>Capacity Then
			
			Message = New UserMessage();
			
			If LoadingForInterval = 0 Then
				Message.Text = NStr("en='For %Resource% in period from %BeginOfPeriod% to %EndOfPeriod% current loading value exceed permissible load. Сurrent load %CurrentLoading%';ru='Для %Resource% в период с %BeginOfPeriod% по %EndOfPeriod% текущее значение загрузки превышает допустимую. Доступная загрузка %CurrentLoading%';vi='Đối với %Resource% trong khoảng thời gian từ %BeginOfPeriod% đến %EndOfPeriod%, giá trị tải hiện tại vượt quá giá trị cho phép. Tải xuống có sẵn %CurrentLoading%'");
				LoadingForInterval = Capacity;
			Else
				Message.Text = NStr("en='For %Resource% in period from %BeginOfPeriod% to %EndOfPeriod% loading with current loading exceed permissible. Сurrent loading %CurrentLoading%';ru='Для %Resource% в период с %BeginOfPeriod% по %EndOfPeriod% загрузка с учетом текущей превышает допустимую. Доступная загрузка %CurrentLoading%';vi='Đối với %Resource% trong khoảng thời gian từ %BeginOfPeriod% đến %EndOfPeriod%, giá trị tải hiện tại vượt quá giá trị cho phép. Tải xuống có sẵn %CurrentLoading%'");
				LoadingForInterval = ?(Capacity - LoadingForInterval > 0, Capacity - LoadingForInterval, 0);
			EndIf;
			
			Message.Text = StrReplace(Message.Text, "%Resource%", String(TableRow.Resource));
			Message.Text = StrReplace(Message.Text, "%BeginOfPeriod%", String(TableRow.BeginOfPeriod));
			Message.Text = StrReplace(Message.Text, "%EndOfPeriod%", String(TableRow.EndOfPeriod));
			Message.Text = StrReplace(Message.Text, "%CurrentLoading%", String(LoadingForInterval));
			Message.Field = "SelectedResources";
			Message.SetData(ThisForm);
			Message.Message();
			
			HasErrors = True;
			
		EndIf;
		
	EndDo;
	
	If Not HasErrors Then
		Message = New UserMessage();
		Message.Text = NStr("en='Errors not found.';ru='Ошибок не обнаружено.';vi='Không có lỗi được tìm thấy.'");
		Message.SetData(ThisForm);
		Message.Message();
	EndIf;
	
EndProcedure

&AtServer
Function DecomposeRowsBySchedule(ScheduleTable)
	
	ExtendedTable = New ValueTable;
	
	ExtendedTable.Columns.Add("Resource");
	ExtendedTable.Columns.Add("BeginOfPeriod");
	ExtendedTable.Columns.Add("EndOfPeriod");
	ExtendedTable.Columns.Add("Loading");
	ExtendedTable.Columns.Add("Period");
	
	For Each TimetableString In ScheduleTable Do
		
		Resource = TimetableString.Resource;
		IntervalBegin = TimetableString.BeginOfPeriod;
		IntervalEnd = TimetableString.EndOfPeriod;
		CompleteAfter = TimetableString.CompleteAfter;
		RepeatInterval = TimetableString.RepeatInterval;
		Loading = TimetableString.Loading;
		RepeatIndex = 0;
		
		If Not BegOfDay(IntervalBegin) = BegOfDay(IntervalEnd) Then
			
			CounterDay = IntervalBegin;
			
			While CounterDay<= BegOfDay(IntervalEnd) Do
				
				NewRow = ExtendedTable.Add();
				NewRow.BeginOfPeriod = CounterDay;
				
				NewRow.EndOfPeriod = ?(BegOfDay(CounterDay)= BegOfDay(IntervalEnd), IntervalEnd, EndOfDay(CounterDay));
				
				NewRow.Loading = Loading;
				NewRow.Resource = Resource;
				NewRow.Period = BegOfDay(CounterDay);
				
				CounterDay = BegOfDay(CounterDay+86401);
			EndDo;
			
			Continue;
		EndIf;
		
		If BegOfDay(IntervalBegin) = BegOfDay(IntervalEnd) And TimetableString.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.NoRepeat") Then
				
				NewRow = ExtendedTable.Add();
				NewRow.BeginOfPeriod = IntervalBegin;
				NewRow.EndOfPeriod = IntervalEnd;
				NewRow.Loading = Loading;
				NewRow.Resource = Resource;
				NewRow.Period = BegOfDay(IntervalBegin);
			
			Continue;
		EndIf;
		
		If TimetableString.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Daily") Then
			
			BeginOfPeriod = IntervalBegin;
			EndOfPeriod = IntervalEnd;
			
			If TimetableString.CompleteKind = PredefinedValue("Enum.ScheduleRepeatCompletingKind.AtDate") Then
				
				BeginOfPeriod = IntervalBegin;
				EndOfPeriod = IntervalEnd;
				
				While BegOfDay(BeginOfPeriod) <= CompleteAfter Do
					
					If RepeatIndex = 0 Or RepeatIndex = RepeatInterval Then
						NewRow = ExtendedTable.Add();
						NewRow.BeginOfPeriod = BeginOfPeriod;
						NewRow.EndOfPeriod = EndOfPeriod;
						NewRow.Loading = Loading;
						NewRow.Resource = Resource;
						NewRow.Period = BegOfDay(BeginOfPeriod);
						
						RepeatIndex = 0;
					EndIf;
					
					RepeatIndex = RepeatIndex + 1;
					BeginOfPeriod = BeginOfPeriod + 86400;
					EndOfPeriod = EndOfPeriod + 86400;
				EndDo;
				
			ElsIf TimetableString.CompleteKind = PredefinedValue("Enum.ScheduleRepeatCompletingKind.ByCounter") Then
				
				RepeatQuantity = 1;
				
				While RepeatQuantity <= CompleteAfter Do
					
					If RepeatIndex = 0 Or RepeatIndex = RepeatInterval Then
						NewRow = ExtendedTable.Add();
						NewRow.BeginOfPeriod = BeginOfPeriod;
						NewRow.EndOfPeriod = EndOfPeriod;
						NewRow.Loading = Loading;
						NewRow.Resource = Resource;
						NewRow.Period = BegOfDay(BeginOfPeriod);
						
						RepeatQuantity = RepeatQuantity + 1;
						RepeatIndex = 0;
					EndIf;
					
					RepeatIndex = RepeatIndex + 1;
					BeginOfPeriod = BeginOfPeriod + 86400;
					EndOfPeriod = EndOfPeriod + 86400;
					
				EndDo;
			EndIf;
			Continue;
		EndIf;
		
		TimeSecBeginInterval = IntervalBegin - BegOfDay(IntervalBegin);
		TimeSecFinishInterval = IntervalEnd - BegOfDay(IntervalEnd);
		YearPeriod = Year(IntervalBegin);
		
		If TimetableString.RepeatKind = "Weekly" Then
			
			ArrayOfWeekDays = ArrayWorkDaysForRepeat(TimetableString);
			
			CurrentWeekNumber = WeekOfYear(IntervalBegin);
			
			If TimetableString.CompleteKind = PredefinedValue("Enum.ScheduleRepeatCompletingKind.AtDate") Then
				
				WeekEndNumber = WeekOfYear(CompleteAfter);
				YearFinish = Year(CompleteAfter);
				
				While YearPeriod <= YearFinish Do
					
					LastYearWeek = WeekOfYear(Date(YearPeriod,12,31,1,1,1));
					WeekendPeriodForYear = ?(YearPeriod <YearFinish, LastYearWeek,WeekEndNumber);
					
					While CurrentWeekNumber < WeekendPeriodForYear Do
						
						If RepeatIndex = 0 Or RepeatIndex = RepeatInterval Then
							
							BegOfWeek = DateBeginOfWeekByNumber(YearPeriod,CurrentWeekNumber);
							
							For Each WeekDay In ArrayOfWeekDays Do
								
								DateByNumber = BegOfDay(BegOfWeek-1+(86400*WeekDay));
								
								If DateByNumber < BegOfDay(IntervalBegin) Then Continue EndIf;
								If DateByNumber > BegOfDay(CompleteAfter) Then Break EndIf;
								
								NewRow = ExtendedTable.Add();
								NewRow.BeginOfPeriod = DateByNumber + TimeSecBeginInterval;
								NewRow.EndOfPeriod = DateByNumber + TimeSecFinishInterval;
								NewRow.Loading = Loading;
								NewRow.Resource = Resource;
								NewRow.Period = BegOfDay(DateByNumber);
								
							EndDo;
							
							RepeatIndex = 0;
						EndIf;
						
						RepeatIndex = RepeatIndex + 1;
						CurrentWeekNumber = CurrentWeekNumber +1;
					EndDo;
					
					CurrentWeekNumber = 1;
					YearPeriod = YearPeriod + 1;
				EndDo;
				
			ElsIf TimetableString.CompleteKind = PredefinedValue("Enum.ScheduleRepeatCompletingKind.ByCounter") Then
				
				LastYearWeek = WeekOfYear(Date(YearPeriod,12,31,1,1,1));
					
				While RepeatIndex < CompleteAfter Do
							
							BegOfWeek = DateBeginOfWeekByNumber(YearPeriod,CurrentWeekNumber);
							
							For Each WeekDay In ArrayOfWeekDays Do
								
								DateByNumber = BegOfDay(BegOfWeek-1+(86400*WeekDay));
								
								If DateByNumber < BegOfDay(IntervalBegin) Then Continue EndIf;
								
								NewRow = ExtendedTable.Add();
								NewRow.BeginOfPeriod = DateByNumber + TimeSecBeginInterval;
								NewRow.EndOfPeriod = DateByNumber + TimeSecFinishInterval;
								NewRow.Loading = Loading;
								NewRow.Resource = Resource;
								NewRow.Period = BegOfDay(DateByNumber);
								
							EndDo;
						
						RepeatIndex = RepeatIndex + 1;
						CurrentWeekNumber = CurrentWeekNumber +RepeatInterval;
						
						If CurrentWeekNumber > LastYearWeek Then
							YearPeriod = YearPeriod+1;
							LastYearWeek = WeekOfYear(Date(YearPeriod,12,31,1,1,1));
							CurrentWeekNumber = 1+RepeatInterval;
						EndIf;
						
					EndDo;
					
			EndIf;
			Continue;
		EndIf;
		
		If TimetableString.RepeatKind =PredefinedValue("Enum.ScheduleRepeatKind.Monthly") Then
			
			If TimetableString.CompleteKind = PredefinedValue("Enum.ScheduleRepeatCompletingKind.AtDate") Then
				
				DecomposeRowsMonthByDate(TimetableString,ExtendedTable);
				
			ElsIf TimetableString.CompleteKind = PredefinedValue("Enum.ScheduleRepeatCompletingKind.ByCounter") Then
				
				DecomposeRowsMonthByCounter(TimetableString,ExtendedTable)
				
			EndIf;
			Continue;
		EndIf;
		
		If TimetableString.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.Annually") Then
			
			MonthNumber = TimetableString.MonthNumber;
			RepeatabilityDate = TimetableString.RepeatabilityDate;
			
			If TimetableString.CompleteKind = PredefinedValue("Enum.ScheduleRepeatCompletingKind.AtDate") Then
				
				If ValueIsFilled(RepeatabilityDate) And ValueIsFilled(MonthNumber) Then
					
					YearPeriod = Year(IntervalBegin);
					YearFinish = Year(CompleteAfter);
					
					While YearPeriod<=YearFinish Do
						
						CounterPeriod = Date(YearPeriod, MonthNumber, RepeatabilityDate, 0,0,0);
						
						NewRow = ExtendedTable.Add();
						NewRow.BeginOfPeriod = CounterPeriod + TimeSecBeginInterval;
						NewRow.EndOfPeriod = CounterPeriod + TimeSecFinishInterval;
						NewRow.Loading = Loading;
						NewRow.Resource = Resource;
						NewRow.Period = BegOfDay(CounterPeriod);
						
						YearPeriod = YearPeriod + RepeatInterval;
					EndDo;
					
				EndIf;
				
			ElsIf TimetableString.CompleteKind = PredefinedValue("Enum.ScheduleRepeatCompletingKind.ByCounter") Then
				
				If ValueIsFilled(RepeatabilityDate) And ValueIsFilled(MonthNumber) Then
					
					RepeatIndex = 1;
					
					While RepeatIndex<=CompleteAfter Do
						
						CounterPeriod = Date(YearPeriod, MonthNumber, RepeatabilityDate, 0,0,0);
						
						NewRow = ExtendedTable.Add();
						NewRow.BeginOfPeriod = CounterPeriod + TimeSecBeginInterval;
						NewRow.EndOfPeriod = CounterPeriod + TimeSecFinishInterval;
						NewRow.Loading = Loading;
						NewRow.Resource = Resource;
						NewRow.Period = BegOfDay(CounterPeriod);
						
						YearPeriod = YearPeriod + RepeatInterval;
						
						RepeatIndex = RepeatIndex + 1;
					EndDo;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return ExtendedTable;
	
EndFunction

&AtServer
Function AreFillingErrors()
	
	IsError = False;
	LineNumber = 1;
	
	For Each RowResource In SelectedResources Do
		
		If Not ValueIsFilled(RowResource.Resource) Then

			TextOfMessage = NStr("en='In row №%Number% tabular. section not specified resource.';ru='В строке №%Number% табл. части не указан ресурс.';vi='Trong dòng số %Number% của bảng không chỉ định tài nguyên.'");
			TextOfMessage = StrReplace(TextOfMessage, "%Number%", LineNumber);
			SmallBusinessServer.ShowMessageAboutError(
			ThisObject,
			TextOfMessage,
			"SelectedResources",
			LineNumber,
			"Resource",
			IsError
			);
			
		EndIf;
		
		If Not ValueIsFilled(RowResource.Loading) Then
			TextOfMessage = NStr("en='In row №%Number% tabular. section not specified loading value.';ru='В строке №%Number% табл. части не указано значение загрузки.';vi='Trong dòng số% Số% của bảng. các bộ phận không chỉ định giá trị tải.'");
			TextOfMessage = StrReplace(TextOfMessage, "%Number%", LineNumber);
			SmallBusinessServer.ShowMessageAboutError(
			ThisObject,
			TextOfMessage,
			"SelectedResources",
			LineNumber,
			"Loading",
			IsError
			);
		EndIf;
		
		If Not ValueIsFilled(RowResource.BeginOfPeriod) Then
			
			TextOfMessage = NStr("en='In row №%Number% tabular. section not specified begin of period(Start)';ru='В строке №%Number% табл. части не указано начало периода(Старт)';vi='Trong dòng số %Number% của bảng không cho biết bắt đầu của giai đoạn (Bắt đầu)'");
			TextOfMessage = StrReplace(TextOfMessage, "%Number%", LineNumber);
			SmallBusinessServer.ShowMessageAboutError(
			ThisObject,
			TextOfMessage,
			"SelectedResources",
			LineNumber,
			"BeginOfPeriod",
			IsError
			);
		EndIf;
		
		If Not ValueIsFilled(RowResource.EndOfPeriod) Then
			
			TextOfMessage = NStr("en='In row №%Number% tabular. section not specified end of period(Finish).';ru='В строке №%Number% табл. части не указано окончание периода(Финиш).';vi='Trong dòng số %Number% của bảng không được chỉ định kết thúc kỳ (kết thúc).'");
			TextOfMessage = StrReplace(TextOfMessage, "%Number%", LineNumber);
			SmallBusinessServer.ShowMessageAboutError(
			ThisObject,
			TextOfMessage,
			"SelectedResources",
			LineNumber,
			"EndOfPeriod",
			IsError
			);
		EndIf;
		
		If BegOfDay(RowResource.BeginOfPeriod) = BegOfDay(RowResource.EndOfPeriod) 
			And ValueIsFilled(RowResource.RepeatKind) And Not RowResource.RepeatKind = PredefinedValue("Enum.ScheduleRepeatKind.NoRepeat") Then
			
			If Not ValueIsFilled(RowResource.CompleteKind) Then
				TextOfMessage = NStr("en='In row №%Number% tabular. section not specified completing kind.';ru='В строке №%Number% табл. части не указан вид завершения.';vi='Trong dòng số %Number% của bảng không không chỉ định dạng hoàn thành.'");
				TextOfMessage = StrReplace(TextOfMessage, "%Number%", LineNumber);
				SmallBusinessServer.ShowMessageAboutError(
				ThisObject,
				TextOfMessage,
				"SelectedResources",
				LineNumber,
				"CompleteKind",
				IsError
				);
				Continue;
			EndIf;
			
			If Not ValueIsFilled(RowResource.CompleteAfter) Then
				TextOfMessage = NStr("en='In row №%Number% tabular. section not specified parameter repeat completing.';ru='В строке №%Number% табл. части не указан параметр окончания повторов.';vi='Trong dòng số %Number% của bảng không chỉ định tham số lặp lại kết thúc.'");
				TextOfMessage = StrReplace(TextOfMessage, "%Number%", LineNumber);
				SmallBusinessServer.ShowMessageAboutError(
				ThisObject,
				TextOfMessage,
				"SelectedResources",
				LineNumber,
				"CompleteAfter",
				IsError
				);
			EndIf;
			
		EndIf;
		
		LineNumber = LineNumber +1;
		
	EndDo;
	
	Return IsError;
	
EndFunction

&AtServer
Procedure DecomposeRowsMonthByDate(TimetableString, ExtendedTable)
	
	Resource = TimetableString.Resource;
	
	IntervalBegin = TimetableString.BeginOfPeriod;
	IntervalEnd = TimetableString.EndOfPeriod;
	CompleteAfter = TimetableString.CompleteAfter;
	
	RepeatInterval = TimetableString.RepeatInterval;
	Loading = TimetableString.Loading;
	
	RepeatabilityDate = TimetableString.RepeatabilityDate;
	WeekDayMonth = TimetableString.WeekDayMonth;
	
	TimeSecBeginInterval = IntervalBegin - BegOfDay(IntervalBegin);
	TimeSecFinishInterval = IntervalEnd - BegOfDay(IntervalEnd);
	
	LastMonthDay = TimetableString.LastMonthDay;
	
	CurMonth = Month(IntervalBegin);
	CurYear = Year(IntervalBegin);
	
	CountingEnd = BegOfMonth(CompleteAfter);
	
	If ValueIsFilled(RepeatabilityDate) Then
		
		CounterPeriod = Date(CurYear, CurMonth, RepeatabilityDate, 0,0,0);
		
		While CounterPeriod <= CountingEnd Do
			
			CurMonth = CurMonth + RepeatInterval;
			
			NewRow = ExtendedTable.Add();
			NewRow.BeginOfPeriod = CounterPeriod + TimeSecBeginInterval;
			NewRow.EndOfPeriod = CounterPeriod + TimeSecFinishInterval;
			NewRow.Loading = Loading;
			NewRow.Resource = Resource;
			NewRow.Period = BegOfDay(CounterPeriod);
			
			If CurMonth>12 Then
				CurYear = CurYear+1;
				CurMonth = CurMonth - 12;
			EndIf;
			
			CounterPeriod = Date(CurYear, CurMonth, RepeatabilityDate, 0,0,0);
			
		EndDo;
		
		Return;
		
	EndIf;
	
	If ValueIsFilled(WeekDayMonth) Then
		
		CounterPeriod = Date(CurYear, CurMonth, 1, 0,0,0);
		
		WeekMonthNumber = TimetableString.WeekMonthNumber;
	
		While CounterPeriod <= CountingEnd Do
			
			WeekBeginMonthByCounter = WeekOfYear(BegOfMonth(CounterPeriod));
			SearchWeek = WeekBeginMonthByCounter + WeekMonthNumber - 1;
			
			DateBeginOfWeek = DateBeginOfWeekByNumber(CurYear,SearchWeek);
			RequiredData =  BegOfDay(DateBeginOfWeek-1+(86400*WeekDayMonth));
			
			If RequiredData > CompleteAfter Then Break EndIf;
			
			CurMonth = CurMonth + RepeatInterval;
			
			NewRow = ExtendedTable.Add();
			NewRow.BeginOfPeriod = RequiredData + TimeSecBeginInterval;
			NewRow.EndOfPeriod = RequiredData + TimeSecFinishInterval;
			NewRow.Loading = Loading;
			NewRow.Resource = Resource;
			NewRow.Period = BegOfDay(RequiredData);
			
			If CurMonth>12 Then
				CurYear = CurYear+1;
				CurMonth = CurMonth - 12;
			EndIf;
			
			CounterPeriod = Date(CurYear, CurMonth, 1, 0,0,0);
			
		EndDo;
		
		Return;
		
	EndIf;
	
	If LastMonthDay Then
		
		CounterPeriod = Date(CurYear, CurMonth, 1, 0,0,0);
		
		While CounterPeriod <= CountingEnd Do
		
			
			RequiredData = BegOfDay(EndOfMonth(CounterPeriod));
			
			If RequiredData > CompleteAfter Then Break EndIf;
			
			CurMonth = CurMonth + RepeatInterval;
			
			NewRow = ExtendedTable.Add();
			NewRow.BeginOfPeriod = RequiredData + TimeSecBeginInterval;
			NewRow.EndOfPeriod = RequiredData + TimeSecFinishInterval;
			NewRow.Loading = Loading;
			NewRow.Resource = Resource;
			NewRow.Period = BegOfDay(RequiredData);
			
			If CurMonth>12 Then
				CurYear = CurYear+1;
				CurMonth = CurMonth - 12;
			EndIf;
			
			CounterPeriod = Date(CurYear, CurMonth, 1, 0,0,0);
			
		EndDo;
		
		Return;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DecomposeRowsMonthByCounter(TimetableString, ExtendedTable)
	
	Resource = TimetableString.Resource;
	
	IntervalBegin = TimetableString.BeginOfPeriod;
	IntervalEnd = TimetableString.EndOfPeriod;
	CompleteAfter = TimetableString.CompleteAfter;
	
	RepeatInterval = TimetableString.RepeatInterval;
	Loading = TimetableString.Loading;
	
	RepeatabilityDate = TimetableString.RepeatabilityDate;
	WeekDayMonth = TimetableString.WeekDayMonth;
	
	TimeSecBeginInterval = IntervalBegin - BegOfDay(IntervalBegin);
	TimeSecFinishInterval = IntervalEnd - BegOfDay(IntervalEnd);
	
	LastMonthDay = TimetableString.LastMonthDay;
	
	CurMonth = Month(IntervalBegin);
	CurYear = Year(IntervalBegin);

	CountingEnd = CompleteAfter;
	CounterPeriod = 1;
	
	If ValueIsFilled(RepeatabilityDate) Then
		
		OutputPeriod = Date(CurYear, CurMonth, RepeatabilityDate, 0,0,0);
		
		While CounterPeriod <= CountingEnd Do
			
			CurMonth = CurMonth + RepeatInterval;
			
			NewRow = ExtendedTable.Add();
			NewRow.BeginOfPeriod = OutputPeriod + TimeSecBeginInterval;
			NewRow.EndOfPeriod = OutputPeriod + TimeSecFinishInterval;
			NewRow.Loading = Loading;
			NewRow.Resource = Resource;
			NewRow.Period = BegOfDay(OutputPeriod);
			
			If CurMonth>12 Then
				CurYear = CurYear+1;
				CurMonth = CurMonth - 12;
			EndIf;
			
			OutputPeriod = Date(CurYear, CurMonth, RepeatabilityDate, 0,0,0);
			CounterPeriod = CounterPeriod +1;
			
		EndDo;
		
		Return;
		
	EndIf;
	
	If ValueIsFilled(WeekDayMonth) Then
		
		OutputPeriod = Date(CurYear, CurMonth, 1, 0,0,0);
		
		WeekMonthNumber = TimetableString.WeekMonthNumber;
	
		While CounterPeriod <= CountingEnd Do
			
			WeekBeginMonthByCounter = WeekOfYear(BegOfMonth(OutputPeriod));
			SearchWeek = WeekBeginMonthByCounter + WeekMonthNumber - 1;
			
			DateBeginOfWeek = DateBeginOfWeekByNumber(CurYear,SearchWeek);
			RequiredData =  BegOfDay(DateBeginOfWeek-1+(86400*WeekDayMonth));
			
			CurMonth = CurMonth + RepeatInterval;
			
			NewRow = ExtendedTable.Add();
			NewRow.BeginOfPeriod = RequiredData + TimeSecBeginInterval;
			NewRow.EndOfPeriod = RequiredData + TimeSecFinishInterval;
			NewRow.Loading = Loading;
			NewRow.Resource = Resource;
			NewRow.Period = BegOfDay(RequiredData);
			
			If CurMonth>12 Then
				CurYear = CurYear+1;
				CurMonth = CurMonth - 12;
			EndIf;
			
			OutputPeriod = Date(CurYear, CurMonth, 1, 0,0,0);
			
			CounterPeriod = CounterPeriod +1;
			
		EndDo;
		
		Return;
		
	EndIf;
	
	If LastMonthDay Then
		
		OutputPeriod = Date(CurYear, CurMonth, 1, 0,0,0);
		
		While CounterPeriod <= CountingEnd Do
		
			RequiredData = BegOfDay(EndOfMonth(OutputPeriod));
			
			CurMonth = CurMonth + RepeatInterval;
			
			NewRow = ExtendedTable.Add();
			NewRow.BeginOfPeriod = RequiredData + TimeSecBeginInterval;
			NewRow.EndOfPeriod = RequiredData + TimeSecFinishInterval;
			NewRow.Loading = Loading;
			NewRow.Resource = Resource;
			NewRow.Period = BegOfDay(RequiredData);
			
			If CurMonth>12 Then
				CurYear = CurYear+1;
				CurMonth = CurMonth - 12;
			EndIf;
			
			OutputPeriod = Date(CurYear, CurMonth, 1, 0,0,0);
			
			CounterPeriod = CounterPeriod +1;
			
		EndDo;
		
		Return;
		
	EndIf;
	
EndProcedure

&AtServer
Function DateBeginOfWeekByNumber(YearNumber,WeekNumber)
	Return BegOfWeek(Date(YearNumber,1,1))+604800*(WeekNumber-1); 
EndFunction

&AtServer
Function ArrayWorkDaysForRepeat(CurrentData)

	DaysArray = New Array;
	
	If CurrentData.Mon Then
		DaysArray.Add(1);
	EndIf;
	If CurrentData.Tu Then
		DaysArray.Add(2);
	EndIf;
	If CurrentData.We Then
		DaysArray.Add(3);
	EndIf;
	If CurrentData.Th Then
		DaysArray.Add(4);
	EndIf;
	If CurrentData.Fr Then
		DaysArray.Add(5);
	EndIf;
	If CurrentData.Sa Then
		DaysArray.Add(6);
	EndIf;
	If CurrentData.Su Then
		DaysArray.Add(7);
	EndIf;
	
	Return DaysArray;
	
EndFunction

