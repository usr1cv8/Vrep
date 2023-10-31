
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("Filter") And Parameters.Filter.Property("Owner") Then
		Resource =  Parameters.Filter.Owner;
	Else
		Return
	EndIf;
	
	ChangingMonthNumber = 0;
	CurrentYearNumber = Year(CurrentSessionDate());
	
	FillGraphAttributesData(CurrentYearNumber);
	
	If TypeOf(Resource) = Type("CatalogRef.Employees") Then
		
		Items.SetSchedule.Visible = False;
		Items.FormHistory.Visible = False;
		
	EndIf;
	
	
	If Not EditAvailable() Then
		RestrictAvailabilityFormItems();
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	GraphForInstalation = SelectedValue;
	
	SetTimetableAtServer();
	
	GeneratePeriodPresentation();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	ThisForm.CurrentItem = Items.TimetableSchedule;
	Items.TimetableSchedule.CurrentArea = TimetableSchedule.Area("R2C3");
	GeneratePeriodPresentation();
EndProcedure

#EndRegion

#Region FormItemEventsHandlers

&AtClient
Procedure CurrentYearNumberTuning(Item, Direction, StandardProcessing)
	
	FillGraphAttributesData(CurrentYearNumber + Direction);
	
EndProcedure

&AtClient
Procedure CurrentYearNumberOnChange(Item)
	
	If Not ValueIsFilled(CurrentYearNumber) Then CurrentYearNumber = Year(CurrentDate()) EndIf;
	
	FillGraphAttributesData(CurrentYearNumber);
EndProcedure

&AtClient
Procedure TimetableScheduleOnChangeAreaContent(Item, Area)
	
	SelectedAreas = Items.TimetableSchedule.GetSelectedAreas();
	
	IsProcessedAreas = False;
	
	FieldValue = Area.Text;
	
	ListDays = New ValueList;
	
	For Each CurArea In SelectedAreas Do
		
		If TypeOf(CurArea) <> Type("SpreadsheetDocumentRange") Then
			Continue;
		EndIf;
		
		For curRow = CurArea.Top To CurArea.Bottom Do
			For CurColumn = CurArea.Left To CurArea.Right Do
				If CurColumn >= 3 And CurColumn <= 33 And curRow >= 2 And curRow <= 13 Then
					Try
						DateOfDay = Date(CurrentYearNumber, curRow - 1, CurColumn - 2, 0, 0, 0);
					Except
						Continue;
					EndTry;
					
					DayNumber = Day(DateOfDay);
					MonthNumber = Month(DateOfDay);
					
					FilterParameters = New Structure("MonthNumber",MonthNumber);
					RowsOfData = ScheduleData.FindRows(FilterParameters);
					
					If Not RowsOfData.Count() Then Continue EndIf;
					DataRow = RowsOfData[0];
					
					Changed = DataRow["Changed"+DayNumber];
					CycleDayNumber = DataRow["CycleDayNumber"+DayNumber];
					
					ListDays.Add(DateOfDay,String(CycleDayNumber),Changed);
					
				EndIf;
			EndDo;
		EndDo;
		
	EndDo;
	
	If Not DaysHaveBreaks(ListDays) Then
		ChangeDaysWithoutBreak(ListDays, FieldValue, IsProcessedAreas);
	Else
		ChangeDaysWitBreak(ListDays, FieldValue, IsProcessedAreas);
	EndIf;
	
	If IsProcessedAreas Then
		WriteDataInRegister(CurrentYearNumber);
		DisplayTimetableSchedule();
	EndIf;
EndProcedure

&AtClient
Function DaysHaveBreaks(ListDays)
	
	For Each ListElement In ListDays Do
		
		DateOfDay = ListElement.Value;
		
		FilterParameters = New Structure("DateOfDay", DateOfDay);
		
		FoundGraphRows = DateByGraphs.FindRows(FilterParameters);
		GraphDay = ?(FoundGraphRows.Count(), FoundGraphRows[0].WorkSchedule, Undefined);
		
		DayNumber = Day(DateOfDay);
		
		If ListElement.Check Then
			FilterParameters = New Structure("DateOfDay", DateOfDay);
			RowsChangedDays = ChangedDays.FindRows(FilterParameters);
			
			If RowsChangedDays.Count() > 1 Then
				Return True
			EndIf;
			
			Continue
		EndIf;
		
		FilterParameters = New Structure("CycleDayNumber, WorkSchedule", Number(ListElement.Presentation), GraphDay);
		RowsCycleDays = Object.GraphPeriods.FindRows(FilterParameters);
		
		If RowsCycleDays.Count() > 1 And Not ListElement.Presentation = "0" Then
			Return True
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

&AtClient
Procedure ChangeDaysWithoutBreak(ListDays, FieldValue, IsProcessedAreas = False)
	
	ChangedDays.Sort("DateOfDay Asc, BeginTime Asc");
	
	For Each ListElement In ListDays Do
		
		DateOfDay = ListElement.Value;
		
		DayNumber = Day(DateOfDay);
		MonthNumber = Month(DateOfDay);
		
		CurrentCycleArea = TimetableSchedule.Area("R" + String(MonthNumber+1) + "C" + String(DayNumber+2));
		
		FilterParameters = New Structure("MonthNumber",MonthNumber);
		
		RowsOfData = ScheduleData.FindRows(FilterParameters);
		
		If Not RowsOfData.Count() Then Return EndIf;
		
		DataRow = RowsOfData[0];
		
		PreviousFieldValue = DataRow["Day"+DayNumber];
		
		If (Not ValueIsFilled(FieldValue) Or FieldValue = "0") And Not ValueIsFilled(PreviousFieldValue) Then
			CurrentCycleArea.Text = "";
			Continue
		EndIf;
		
		If (Not ValueIsFilled(FieldValue) Or FieldValue = "0") Then
			If ValueIsFilled(PreviousFieldValue) Then
				If ListElement.Check Then
					CleanChangedFieldsDays(DateOfDay);
				EndIf;
				CleanScheduleClient(True, True);
				IsProcessedAreas = True;
				DataRow["Day"+DayNumber] = 0;
				CalculateWorkHours(DataRow.MonthNumber);
			EndIf;
			CurrentCycleArea.Text = "";
			Continue
		EndIf;
		
		Try
			NewFieldValue = Number(FieldValue);
			
			If NewFieldValue = PreviousFieldValue Then Continue EndIf;
			
			If NewFieldValue > 24 Then
				
				CurrentCycleArea.Text = String(?(PreviousFieldValue = 0,"",PreviousFieldValue));
				RestorePreviuosFieldsValue(ListDays);
				Break;
				
			EndIf;
			
			DataRow["Day"+DayNumber] = NewFieldValue;
			CurrentCycleArea.Text = NewFieldValue;
			CalculateWorkHours(DataRow.MonthNumber);
			
			If ListElement.Check Then
				
				FilterParameters = New Structure("DateOfDay", DateOfDay);
				RowsChangedDays = ChangedDays.FindRows(FilterParameters);
				
				If Not RowsChangedDays.Count() Then Continue EndIf;
				
				BreakHours = RowsChangedDays[0].BreakHours;
				BreakHours= ?(NewFieldValue = 24, 0, RowsChangedDays[0].BreakHours);
				
				If NewFieldValue + BreakHours>24
					Then
					BreakHours = 24 - NewFieldValue;
				EndIf;
				
				RowsChangedDays[0].BreakHours = BreakHours;
				
				BeginTime = ?(ValueIsFilled(RowsChangedDays[0].BeginTime),RowsChangedDays[0].BeginTime,Date(1,1,1,8,0,0));
				
				TimeDifferenceDate = (BeginTime + (NewFieldValue+BreakHours)*60*60);
				TimeDifference = (Date(1,1,1)-TimeDifferenceDate)*-1;
				EndTime = ?(TimeDifference<0, TimeDifference* -1, TimeDifference);
				
				If EndTime>=86400 Then
					BeginTime = Date(1,1,1) + (86400 - (NewFieldValue+BreakHours)*60*60);
					EndTime = Date(1,1,1);
				Else
					BeginTime = RowsChangedDays[RowsChangedDays.Count()-1].BeginTime;
					EndTime = Date(1,1,1)+ EndTime;
				EndIf;
				
				RowsChangedDays[RowsChangedDays.Count()-1].BeginTime = BeginTime;
				RowsChangedDays[RowsChangedDays.Count()-1].EndTime = EndTime;
				RowsChangedDays[RowsChangedDays.Count()-1].IsVariance = True;
				RowsChangedDays[RowsChangedDays.Count()-1].Duration = NewFieldValue;
				
				IsProcessedAreas = True;
				
				Continue;
			EndIf;
			
			If ValueIsFilled(NewFieldValue) Then
				
				BreakHours = 0;
				
				NewRow = ChangedDays.Add();
				
				BeginTime = 28800;
				EndTime = BeginTime + (NewFieldValue+BreakHours)*60*60;
				
				If EndTime>=86400 Then
					BeginTime = Date(1,1,1) + (86400 - (NewFieldValue+BreakHours)*60*60);
					EndTime = Date(1,1,1);
				Else
					BeginTime = Date(1,1,1) + 28800;
					EndTime = BeginTime + (NewFieldValue+BreakHours)*60*60;
				EndIf;
				
				NewRow.BeginTime = BeginTime;
				NewRow.EndTime = EndTime;
				
				NewRow.Duration = (NewFieldValue+BreakHours);
				NewRow.DateOfDay = DateOfDay;
				NewRow.IsVariance = True;
				
				DataRow["Changed"+DayNumber] = True;
				
			EndIf;
			
			IsProcessedAreas = True;
			
			CalculateWorkHours(MonthNumber);
			
		Except
			CurrentCycleArea.Text = String(?(PreviousFieldValue = 0,"",PreviousFieldValue));
			Return;
		EndTry;
		
	EndDo;
EndProcedure

&AtClient
Function IntervalsBreakCorrect(ListDays, NewFieldValue)
	
	ChangedDays.Sort("DateOfDay Asc, BeginTime Asc");
	
	If NewFieldValue = 24 Then Return False EndIf;
	If NewFieldValue = 0 Then Return True EndIf;
	
	For Each ListElement In ListDays Do
		
		DateOfDay = ListElement.Value;
		DayNumber = Day(DateOfDay);
		MonthNumber = Month(DateOfDay);
		
		FilterParameters = New Structure("DateOfDay", DateOfDay);
		
		FoundGraphRows = DateByGraphs.FindRows(FilterParameters);
		GraphDay = ?(FoundGraphRows.Count(), FoundGraphRows[0].WorkSchedule, Undefined);
		
		FilterParameters = New Structure("MonthNumber",MonthNumber);
		RowsOfData = ScheduleData.FindRows(FilterParameters);
		
		If Not RowsOfData.Count() Then Continue EndIf;
		
		DataRow = RowsOfData[0];
		PreviousValueWorkTime = DataRow["Day"+DayNumber];
		
		If ListElement.Check Then
			
			FilterParameters = New Structure("DateOfDay", DateOfDay);
			RowsChangedDays = ChangedDays.FindRows(FilterParameters);
			
			If Not RowsChangedDays.Count() Then Continue EndIf;
			
			TimeBeginWorkDay = RowsChangedDays[0].BeginTime;
			TimeFinishWorkDay = RowsChangedDays[RowsChangedDays.Count()-1].EndTime;
			
			WorkDayIntervalDifference = (TimeFinishWorkDay-TimeBeginWorkDay)/3600;
			DurationPeriod = ?(WorkDayIntervalDifference < 0,24 + WorkDayIntervalDifference, WorkDayIntervalDifference);
			BreakHours = DurationPeriod - PreviousValueWorkTime;
			
			TimeDifferenceDate = (TimeBeginWorkDay + (NewFieldValue+BreakHours)*60*60);
			TimeDifference = (Date(1,1,1)-TimeDifferenceDate)*-1;
			EndTime = ?(TimeDifference<0, TimeDifference* -1, TimeDifference);
			
			If EndTime>=86400 Then Return False EndIf;
			
			EndTime = Date(1,1,1)+ EndTime;
			
			RowIndex = 1;
			
			For Each RowDay In RowsChangedDays Do
				
				If RowDay.BeginTime>=EndTime Then
					Return False
				EndIf;
				
				RowIndex = RowIndex+1;
				
			EndDo;
			
			Continue
			
		EndIf;
		
		CycleDayNumber = Number(ListElement.Presentation);
		FilterParameters = New Structure("CycleDayNumber, WorkSchedule", CycleDayNumber, GraphDay);
		RowsCycleDays = Object.GraphPeriods.FindRows(FilterParameters);
		
		If Not RowsCycleDays.Count() Then Continue EndIf;
		
		TimeBeginWorkDay = RowsCycleDays[0].BeginTime;
		TimeFinishWorkDay = RowsCycleDays[RowsCycleDays.Count()-1].EndTime;
		
		WorkDayIntervalDifference = (TimeFinishWorkDay-TimeBeginWorkDay)/3600;
		DurationPeriod = ?(WorkDayIntervalDifference < 0,24 + WorkDayIntervalDifference, WorkDayIntervalDifference);
		BreakHours = DurationPeriod - PreviousValueWorkTime;
		
		TimeDifferenceDate = (TimeBeginWorkDay + (NewFieldValue+BreakHours)*60*60);
		TimeDifference = (Date(1,1,1)-TimeDifferenceDate)*-1;
		EndTime = ?(TimeDifference<0, TimeDifference* -1, TimeDifference);
		
		If EndTime>=86400 Then Return False EndIf;
		
		EndTime = Date(1,1,1)+EndTime;
		
		RowIndex = 1;
		
		For Each RowDay In RowsCycleDays Do
			
			If RowDay.BeginTime>=EndTime Then
				Return False
			EndIf;
			
			RowIndex = RowIndex+1;
			
		EndDo;
		
	EndDo;
	
	Return True;
	
EndFunction

&AtClient
Procedure RestorePreviuosFieldsValue(ListDays)
	
	For Each ListElement In ListDays Do
		
		DateOfDay = ListElement.Value;
		
		DayNumber = Day(DateOfDay);
		MonthNumber = Month(DateOfDay);
		
		CurrentCycleArea = TimetableSchedule.Area("R" + String(MonthNumber+1) + "C" + String(DayNumber+2));
		
		FilterParameters = New Structure("MonthNumber",MonthNumber);
		
		RowsOfData = ScheduleData.FindRows(FilterParameters);
		
		If Not RowsOfData.Count() Then Return EndIf;
		
		DataRow = RowsOfData[0];
		
		PreviousFieldValue = DataRow["Day"+DayNumber];
		
		CurrentCycleArea.Text = String(?(PreviousFieldValue = 0,"",PreviousFieldValue));
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ChangeDaysWitBreak(ListDays, NewFieldValue, IsProcessedAreas = False)
	
	NewFieldValueCorrect = True;
	
	Try
		NewFieldValue = Number(NewFieldValue);
		
		If NewFieldValue>24 Then
			NewFieldValueCorrect = False
		EndIf;
		
	Except 
		RestorePreviuosFieldsValue(ListDays);
		Return;
	EndTry;
	
	If NewFieldValueCorrect And Not IntervalsBreakCorrect(ListDays, NewFieldValue) Then
		
		If Not ListDays.Count() Then Return EndIf;
		
		AdditNotificationParameters = New Structure("ListDays", ListDays);
		
		NotifyDescription = New NotifyDescription(
		"FixChangedPeriodSelectedDays",
		ThisObject,
		AdditNotificationParameters);
		
		OpenParameters = New Structure;
		OpenParameters.Insert("DateOfDay", Date(1,1,1));
		OpenParameters.Insert("Object", Object);
		OpenParameters.Insert("CycleDayNumber", 0);
		OpenParameters.Insert("Changed", False);
		OpenParameters.Insert("ChangedDays", ChangedDays);
		OpenParameters.Insert("WorkingHours", 0);
		OpenParameters.Insert("SelectedInterval", True);
		OpenParameters.Insert("ListDays", ListDays);
		OpenParameters.Insert("ErrorText", NStr("en='Boundaries periods output for boundaries wirk day. When edit schedule will updated current.';vi='Kết quả thời gian ranh giới cho ngày làm việc ranh giới. Khi chỉnh sửa lịch trình sẽ cập nhật hiện tại.'"));
		
		OpenForm("Catalog.WorkSchedules.Form.FormChangeSchedule", OpenParameters,,,,, NotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
		
		Return
	EndIf;
	
	For Each ListElement In ListDays Do
		
		DateOfDay = ListElement.Value;
		
		FilterParameters = New Structure("DateOfDay", DateOfDay);
		
		FoundGraphRows = DateByGraphs.FindRows(FilterParameters);
		GraphDay = ?(FoundGraphRows.Count(), FoundGraphRows[0].WorkSchedule, Undefined);
		
		DayNumber = Day(DateOfDay);
		MonthNumber = Month(DateOfDay);
		
		CurrentCycleArea = TimetableSchedule.Area("R" + String(MonthNumber+1) + "C" + String(DayNumber+2));
		
		FilterParameters = New Structure("MonthNumber",MonthNumber);
		
		RowsOfData = ScheduleData.FindRows(FilterParameters);
		
		If Not RowsOfData.Count() Then Return EndIf;
		
		DataRow = RowsOfData[0];
		
		PreviousFieldValue = DataRow["Day"+DayNumber];
		
		If (Not ValueIsFilled(NewFieldValue) Or NewFieldValue = "0") And Not ValueIsFilled(PreviousFieldValue) Then
			CurrentCycleArea.Text = "";
			Continue
		EndIf;
		
		If (Not ValueIsFilled(NewFieldValue) Or NewFieldValue = "0") Then
			If ValueIsFilled(PreviousFieldValue) Then
				If ListElement.Check Then
					CleanChangedFieldsDays(DateOfDay);
				EndIf;
				CleanScheduleClient(True, True);
				IsProcessedAreas = True;
				DataRow["Day"+DayNumber] = 0;
			EndIf;
			CurrentCycleArea.Text = "";
			Continue
		EndIf;
		
		If NewFieldValue = PreviousFieldValue Then Continue EndIf;
		
		If NewFieldValue > 24 Then 
			
			CurrentCycleArea.Text = String(?(PreviousFieldValue = 0,"",PreviousFieldValue));
			RestorePreviuosFieldsValue(ListDays);
			Break;
			
		EndIf;
		
		DataRow["Day"+DayNumber] = NewFieldValue;
		CurrentCycleArea.Text = NewFieldValue;
		
		If ListElement.Check Then
			
			FilterParameters = New Structure("DateOfDay", DateOfDay);
			RowsChangedDays = ChangedDays.FindRows(FilterParameters);
			
			If Not RowsChangedDays.Count() Then Continue EndIf;
			
			TimeBeginWorkDay = RowsChangedDays[0].BeginTime;
			TimeFinishWorkDay = RowsChangedDays[RowsChangedDays.Count()-1].EndTime;
			
			WorkDayIntervalDifference = (TimeFinishWorkDay-TimeBeginWorkDay)/3600;
			DurationPeriod = ?(WorkDayIntervalDifference < 0,24 + WorkDayIntervalDifference, WorkDayIntervalDifference);
			BreakHours = DurationPeriod - PreviousFieldValue;
			
			TimeDifferenceDate = (TimeBeginWorkDay + (NewFieldValue+BreakHours)*60*60);
			TimeDifference = (Date(1,1,1)-TimeDifferenceDate)*-1;
			EndTime = ?(TimeDifference<0, TimeDifference* -1, TimeDifference);
			
			If EndTime=86400 Then
				EndTime = Date(1,1,1);
			Else
				EndTime = Date(1,1,1) + EndTime;
			EndIf;
			
			RowsChangedDays[RowsChangedDays.Count()-1].EndTime = EndTime;
			RowsChangedDays[RowsChangedDays.Count()-1].Duration = NewFieldValue;
			
			For Each RowDay In RowsChangedDays Do
				RowDay.IsVariance = True;
			EndDo;
			
			IsProcessedAreas = True;
			
			Continue
		EndIf;
		
		CycleDayNumber = Number(ListElement.Presentation);
		FilterParameters = New Structure("CycleDayNumber, WorkSchedule", CycleDayNumber, GraphDay);
		RowsCycleDays = Object.GraphPeriods.FindRows(FilterParameters);
		
		If Not RowsCycleDays.Count() Then Continue EndIf;
		
		TimeBeginWorkDay = RowsCycleDays[0].BeginTime;
		TimeFinishWorkDay = RowsCycleDays[RowsCycleDays.Count()-1].EndTime;
		
		WorkDayIntervalDifference = (TimeFinishWorkDay-TimeBeginWorkDay)/3600;
		DurationPeriod = ?(WorkDayIntervalDifference < 0,24 + WorkDayIntervalDifference, WorkDayIntervalDifference);
		BreakHours = DurationPeriod - PreviousFieldValue;
		
		TimeDifferenceDate = (TimeBeginWorkDay + (NewFieldValue+BreakHours)*60*60);
		TimeDifference = (Date(1,1,1)-TimeDifferenceDate)*-1;
		EndTime = ?(TimeDifference<0, TimeDifference* -1, TimeDifference);
		
		EndTime = Date(1,1,1)+ EndTime;
		
		PeriodsQuantity = RowsCycleDays.Count();
		IndexPeriod = 1;
		
		For Each RowCycleDay In RowsCycleDays Do
			
			NewRow = ChangedDays.Add();
			
			FillPropertyValues(NewRow, RowCycleDay);
			
			NewRow.DateOfDay = DateOfDay;
			DataRow["Changed"+DayNumber] = True;
			
			If IndexPeriod = PeriodsQuantity Then
				NewRow.EndTime = EndTime;
				NewRow.Duration = (NewRow.EndTime - NewRow.BeginTime)/3600;
			EndIf;
			
			NewRow.IsVariance = True;
			
			IndexPeriod = IndexPeriod + 1;
		EndDo;
		
		DataRow["Changed"+DayNumber] = True;
		
		IsProcessedAreas = True;
		
		CalculateWorkHours(MonthNumber);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure CleanScheduleClient(IsProcessedAreas = False, IsVariance = False)
	SelectedAreas = Items.TimetableSchedule.GetSelectedAreas();
	
	For Each CurArea In SelectedAreas Do
		
		If TypeOf(CurArea) <> Type("SpreadsheetDocumentRange") Then
			Continue;
		EndIf;
		
		For curRow = CurArea.Top To CurArea.Bottom Do
			For CurColumn = CurArea.Left To CurArea.Right Do
				If CurColumn >= 3 And CurColumn <= 33 And curRow >= 2 And curRow <= 13 Then
					Try
						DateOfDay = Date(CurrentYearNumber, curRow - 1, CurColumn - 2, 0, 0, 0);
					Except
						Continue;
					EndTry;
					
					DayNumber = Day(DateOfDay);
					MonthNumber = Month(DateOfDay);
					
					DataRow = ScheduleData[Month(DateOfDay)-1];
					
					If DataRow["Day"+String(DayNumber)] = 0 Then Continue EndIf;
					
					CleanChangedFieldsDays(DateOfDay);
					
					DataRow["Day"+String(DayNumber)] = 0;
					DataRow["Changed"+String(DayNumber)] = True;
					
					NewRow = ChangedDays.Add();
					NewRow.Duration = 0;
					NewRow.DateOfDay = DateOfDay;
					NewRow.IsVariance = IsVariance;
					
					IsProcessedAreas = True;
					
					CalculateWorkHours(MonthNumber);
				EndIf;
			EndDo;
		EndDo;
		
	EndDo;
	
	If IsProcessedAreas Then
		ThisForm.Modified = True;
	Else
		Message = New UserMessage;
		Message.Text = NStr("en='Select day or period calendar In table!';vi='Chọn lịch ngày hoặc lịch Trong bảng!'");
		Message.DataKey = Object.Ref;
		Message.Message();
	EndIf;
	
EndProcedure

&AtClient
Procedure FielGraphRepresetationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If GraphListHref.Count() = 1 Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Key", GraphListHref[0].Value);
		
		OpenForm("Catalog.WorkSchedules.ObjectForm", FormParameters,ThisForm,,,,, FormWindowOpeningMode.LockOwnerWindow);
		
	ElsIf GraphListHref.Count() > 1
		Then
		
		NotificationParameters = New Structure();
		Notification = New NotifyDescription("AfterGraphChoice", ThisForm, NotificationParameters);
		
		GraphListHref.ShowChooseItem(Notification,NStr("en='Графики за период';ru='Графики за период';vi='Biểu đồ cho giai đoạn'"),ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure TimetableScheduleOnActivate(Item)
	
	GeneratePeriodPresentation();
	
EndProcedure

&AtClient
Procedure TimetableScheduleSelection(Item, Area, StandardProcessing)
	
	#If Not MobileClient Then
		Return;
	#EndIf
	
	NotificationParameters = New Structure;
	
	List = New ValueList;
	List.Add("Edit",,False, PictureLib.Change);
	List.Add("Clear",,False,PictureLib.Clear);
	List.Add("Delete rejections",,False);
	List.Add("Delete all rejections",,False);
	Notification = New NotifyDescription("AfterChoiceFormMenu",ThisForm,NotificationParameters);
	ShowChooseFromMenu(Notification, List, Items.TimetableSchedule);
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure CleanDeviations(Command)
	CleanDeviationsAtServer();
EndProcedure

&AtClient
Procedure CleanDeviationsForPeriod(Command)
	CleanDeviationsForPeriodClient();
EndProcedure

&AtClient
Procedure ChangeSchedule(Command)
	
	ChangeScheduleClient();
	
EndProcedure

&AtClient
Procedure CleanSchedule(Command)
	
	CleanScheduleClientInteractive();
	
EndProcedure

&AtClient
Procedure History(Command)
	OpenForm("InformationRegister.ResourcesWorkSchedules.ListForm",  New Structure("EnterpriseResource", Resource), Resource);
EndProcedure

&AtClient
Procedure SetSchedule(Command)
	
	SelectedAreas = Items.TimetableSchedule.GetSelectedAreas();
	
	If Not SelectedAreas.Count() Then 
		Return
	EndIf;
	
	If SelectedAreas.Count()> 1 Then 
		Return
	EndIf;
	
	CurArea = SelectedAreas[0];
	
	If TypeOf(CurArea) <> Type("SpreadsheetDocumentRange") Then
		Return;
	EndIf;
	
	If Not CurArea.Top = CurArea.Bottom And Not CurArea.Left = CurArea.Right Then
		Return
	EndIf;
	
	curRow = CurArea.Top;
	CurColumn = CurArea.Left;
	
	If CurColumn >= 3 And CurColumn <= 33 And curRow >= 2 And curRow <= 13 Then
		Try
			DateOfDay = Date(CurrentYearNumber, curRow - 1, CurColumn - 2, 0, 0, 0);
			
			FilterParameters = New Structure("DateOfDay", DateOfDay);
			
			FoundStrings = DateByGraphs.FindRows(FilterParameters);
			
			GraphDateInstalation = DateOfDay;
			GraphForInstalation = ?(FoundStrings.Count(),FoundStrings[0].WorkSchedule, Undefined);
			
		Except
			GraphForInstalation = Undefined;
			GraphDateInstalation = Undefined;
			Raise
		EndTry;
	EndIf;
	
	AfterDateNoGraphBeforeYearEnd = True;
	
	For Each RowGraphForYear In GraphWorkForYear Do
		
		If DateOfDay < RowGraphForYear.Period Then
			AfterDateNoGraphBeforeYearEnd = False;
			Break;
		EndIf;
		
	EndDo;
	
	If Not AfterDateNoGraphBeforeYearEnd Then
		
		Notification = New NotifyDescription("SetTimetableEnd",ThisForm);
		Mode = QuestionDialogMode.YesNoCancel;
		Text = NStr("en='Установить график до окончания текущего года?';ru='Установить график до окончания текущего года?';vi='Đặt lịch trước cuối năm nay?'");
		ShowQueryBox(Notification,Text, Mode, 0);
	Else
		UpdateEndYear = True;
		OpenForm("Catalog.WorkSchedules.ChoiceForm", New Structure("CurrentRow", GraphForInstalation), ThisForm);
	EndIf
EndProcedure

&AtClient
Procedure UpdateGraph(Command)
	FillGraphAttributesData(CurrentYearNumber);
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Function EditAvailable()

	ListAccessProfile = New ValueList;
	
	ListAccessProfile.Add(Catalogs.AccessGroupsProfiles.FindByDescription("Salary"));
	ListAccessProfile.Add(Catalogs.AccessGroupsProfiles.FindByDescription("Production"));
	ListAccessProfile.Add(Catalogs.AccessGroupsProfiles.FindByDescription("Sales"));
	ListAccessProfile.Add(Catalogs.AccessGroupsProfiles.Administrator);
	
	If Not ListAccessProfile.Count() Then Return False EndIf;
	
	Query = New Query;
	
	Query.SetParameter("ListAccessProfile", ListAccessProfile);
	Query.SetParameter("User", Users.AuthorizedUser());
	
	Query.Text = 
	"SELECT
	|	AccessGroupsUsers.Ref AS Ref
	|FROM
	|	Catalog.AccessGroups.Users AS AccessGroupsUsers
	|WHERE
	|	AccessGroupsUsers.User = &User
	|	AND AccessGroupsUsers.Ref.Profile IN(&ListAccessProfile)";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

&AtServer
Procedure RestrictAvailabilityFormItems()
	
	 Items.GroupSubmenu.Visible = False;
	 Items.SetSchedule.Visible = False;
	 Items.FormHistory.Visible = False;
	 Items.ScheduleByGraphContexBarGroupChange.Visible = False;
	 Items.GroupActions.Visible = False;
	 
	 Items.TimetableSchedule.ReadOnly = True;
	 
	 Items.FielGraphRepresetation.Enabled = False;
	 
EndProcedure

&AtServer
Procedure FillGraphAttributesData(YearNumber)
	
	Object.TemplateByYear.Clear();
	Object.Breaks.Clear();
	Object.GraphPeriods.Clear();
	Object.AdditionalFillingSettingsPeriods.Clear();
	Object.WorkSchedule.Clear();
	Object.AdditionalFillingSettings.Clear();
	
	GraphWorkForYear.Clear();
	
	Query = New Query;
	
	Query.SetParameter("YearNumber", YearNumber);
	Query.SetParameter("Resource", Resource);
	Query.SetParameter("BegOfYear", BegOfYear(Date(YearNumber,1,1)));
	
	If TypeOf(Resource) = Type("CatalogRef.Employees") Then 
		
		Query.Text = 
		"SELECT DISTINCT
		|	Employees.WorkSchedule AS WorkSchedule,
		|	Employees.Period AS Period,
		|	Employees.WorkSchedule.BusinessCalendar AS BusinessCalendar,
		|	Employees.WorkSchedule.AccountHolidays AS AccountHolidays
		|FROM
		|	InformationRegister.Employees AS Employees
		|WHERE
		|	YEAR(Employees.Period) = &YearNumber
		|	AND Employees.Employee = &Resource
		|	AND NOT Employees.WorkSchedule = VALUE(Catalog.WorkSchedules.EmptyRef)
		|
		|UNION
		|
		|SELECT
		|	StaffSliceLast.WorkSchedule,
		|	StaffSliceLast.Period,
		|	StaffSliceLast.WorkSchedule.BusinessCalendar,
		|	StaffSliceLast.WorkSchedule.AccountHolidays
		|FROM
		|	InformationRegister.Employees.SliceLast(
		|			&BegOfYear,
		|			Employee = &Resource
		|				AND NOT WorkSchedule = VALUE(Catalog.WorkSchedules.EmptyRef)) AS StaffSliceLast
		|
		|ORDER BY
		|	Period";
		
		
	Else
		Query.Text = 
		"SELECT
		|	ResourcesWorkSchedules.WorkSchedule AS WorkSchedule,
		|	ResourcesWorkSchedules.Period AS Period,
		|	ResourcesWorkSchedules.WorkSchedule.BusinessCalendar AS BusinessCalendar,
		|	ResourcesWorkSchedules.WorkSchedule.AccountHolidays AS AccountHolidays
		|FROM
		|	InformationRegister.ResourcesWorkSchedules AS ResourcesWorkSchedules
		|WHERE
		|	ResourcesWorkSchedules.EnterpriseResource = &Resource
		|	AND NOT ResourcesWorkSchedules.WorkSchedule = VALUE(Catalog.WorkSchedules.EmptyRef)
		|	AND YEAR(ResourcesWorkSchedules.Period) = &YearNumber
		|
		|UNION
		|
		|SELECT
		|	ResourcesWorkSchedulesSliceLast.WorkSchedule,
		|	ResourcesWorkSchedulesSliceLast.Period,
		|	ResourcesWorkSchedulesSliceLast.WorkSchedule.BusinessCalendar,
		|	ResourcesWorkSchedulesSliceLast.WorkSchedule.AccountHolidays
		|FROM
		|	InformationRegister.ResourcesWorkSchedules.SliceLast(
		|			&BegOfYear,
		|			EnterpriseResource = &Resource
		|				AND NOT WorkSchedule = VALUE(Catalog.WorkSchedules.EmptyRef)) AS ResourcesWorkSchedulesSliceLast
		|
		|ORDER BY
		|	Period";
		
	EndIf;
	
	SelectionGraphs = Query.Execute().Select();
	
	GraphListWorks = New ValueTable;
	GraphList.Clear();
	
	ArrayProseccedGraphs = New Array;
	
	While SelectionGraphs.Next() Do
		
		NewRow = GraphWorkForYear.Add();
		FillPropertyValues(NewRow, SelectionGraphs);
		
		UpdateGraphData(SelectionGraphs.WorkSchedule, ArrayProseccedGraphs);
		
		ArrayProseccedGraphs.Add(SelectionGraphs.WorkSchedule);
		
	EndDo;
	
	GraphListWorks = GraphWorkForYear.Unload(,"WorkSchedule");
	GraphListWorks.GroupBy("WorkSchedule");
	
	GraphList.LoadValues(GraphListWorks.UnloadColumn("WorkSchedule"));
	GraphList.SortByValue(SortDirection.Asc);
	
	ProcessGraphData(YearNumber);
	
	DisplayTimetableSchedule(YearNumber);
	
EndProcedure

&AtServer
Procedure DisplayTimetableSchedule(YearNumber = Undefined)
	
	YearNumber = ?(ValueIsFilled(YearNumber), YearNumber, CurrentYearNumber);
	
	TimetableSchedule.Clear();
	
	If Not ScheduleData.Count() Then Return EndIf;
	
	TimetableSchedule.FixedLeft = 2;
	TimetableSchedule.FixedTop = 1;
	
	TimetableScheduleTemplate = DataProcessors.WorkSchedules.GetTemplate("WorkSchedule");
	
	TemplateArea = TimetableScheduleTemplate.GetArea("Header");
	TimetableSchedule.Put(TemplateArea);
	
	TemplateArea = TimetableScheduleTemplate.GetArea("Calendar");
	TimetableSchedule.Put(TemplateArea);
	
	For Each DataRow In ScheduleData Do
		
		MonthNumber = DataRow.MonthNumber;
		
		DaysNumber = DataRow.NumberOfDaysInMonth;
		
		For DayNumber = 1 To 31 Do
			
			If DayNumber = 1 Then
				Area = TimetableSchedule.Area("R" + String(MonthNumber + 1) + "C" + String(DayNumber + 1));
				Area.Text = DataRow.DayHoursRepresentation;
			EndIf;
			
			Area = TimetableSchedule.Area("R" + String(MonthNumber + 1) + "C" + String(DayNumber + 2));
			Area.Text = "";
			If DayNumber > DaysNumber Then
				
				Area.Font = New Font(, 10, True, , , );
				Area.BackColor = StyleColors.InaccessibleDataColor;
				Area.Text = "X";
				
			Else
				
				DateOfDay = Date(YearNumber, MonthNumber, DayNumber, 0, 0, 0);
				StringDayNumber = String(DayNumber);
				
				ColumnDayKind = "DayKind"+StringDayNumber;
				ColumnDay = "Day"+ StringDayNumber;
				Changed = "Changed" + StringDayNumber;
				
				FilterParameters = New Structure("IsVariance, DateOfDay", True, DateOfDay);
				IsDeviationsForDay = ChangedDays.FindRows(FilterParameters);
				
				If Not IsDeviationsForDay.Count() Then
					
					SearchParameters = New Structure("DateOfDay", DateOfDay);
					
					FoundStrings = DateByGraphs.FindRows(SearchParameters);
					
					If FoundStrings.Count() Then
						
						If ValueIsFilled(FoundStrings[0].WorkSchedule) 
							And Not FoundStrings[0].WorkSchedule.Color.Get() = New Color(0, 0, 0) 
							And Not FoundStrings[0].WorkSchedule.Color.Get() = Undefined Then
							
							Area.Pattern = SpreadsheetDocumentPatternType.Pattern15;
							Area.PatternColor = FoundStrings[0].WorkSchedule.Color.Get();
							
						EndIf;
					EndIf;
				EndIf;
				
				// Раскраска выходных дней.
				If DataRow[ColumnDayKind] = Enums.BusinessCalendarDayKinds.Sunday
					Or DataRow[ColumnDayKind] = Enums.BusinessCalendarDayKinds.Saturday
					Or DataRow[ColumnDayKind] = Enums.BusinessCalendarDayKinds.Preholiday
					Or DataRow[ColumnDayKind] = Enums.BusinessCalendarDayKinds.Holiday Then
					
					Area.BackColor = StyleColors.NonWorkingTimeDayOff;
					
				EndIf;
				
				If DataRow[Changed] = True Then
					
					FilterParameters = New Structure("IsVariance, DateOfDay", True, DateOfDay);
					
					IsDeviationsForDay = ChangedDays.FindRows(FilterParameters);
					
					If IsDeviationsForDay.Count() Then
						Area.BackColor = StyleColors.WorktimeCompletelyBusy;
					EndIf
				EndIf;
				
				If DateOfDay = BegOfDay(CurrentSessionDate()) Then
					Area.Comment.Text = NStr("en='Current date';vi='Ngày hiện tại'")
				EndIf;
				
				Area.Text = DataRow[ColumnDay];
				Area.Protection = False;
				//КонецЕсли;
				
			EndIf;
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ProcessGraphData(YearNumber = Undefined, FillingNextYear = False)
	
	ScheduleData.Clear();
	
	YearNumber = ?(Not YearNumber = Undefined, YearNumber, CurrentYearNumber);
	
	FilterParameters = New Structure("Year", YearNumber);
	RowTemplateByYear = Object.TemplateByYear.FindRows(FilterParameters);
	
	If RowTemplateByYear.Count() Then
		TemplateGraphFill = RowTemplateByYear[0].TemplateGraphFill;
		BeginnigDate = RowTemplateByYear[0].BeginnigDate;
		ScheduleType = RowTemplateByYear[0].ScheduleType;
	EndIf;
	
	UpdateProductionGraphCalendar(True, YearNumber);
	
	If Not ScheduleData.Count() Then Return EndIf;
	
	FillGraphData(YearNumber);
	
	MatchDayGraphs(YearNumber);
	
	DisplayTimetableSchedule(YearNumber);
	
EndProcedure

&AtServer
Procedure MatchDayGraphs(YearNumber)
	
	DateByGraphs.Clear();
	
	For Each DataRow In ScheduleData Do
		
		NumberOfDaysInMonth = DataRow.NumberOfDaysInMonth;
		
		For DayNumber = 1 To NumberOfDaysInMonth Do
			
			DateOfDay = Date(YearNumber, DataRow.MonthNumber, DayNumber);
			
			GraphDate = Undefined;
			
			For Each RowGraphsForYear In GraphWorkForYear Do
				
				If DateOfDay>=RowGraphsForYear.Period Then
					GraphDate = RowGraphsForYear.WorkSchedule;
				EndIf;
				
			EndDo;
			
			NewRow = DateByGraphs.Add();
			NewRow.DateOfDay = DateOfDay;
			NewRow.WorkSchedule = GraphDate;
			
			FilterParameters = New Structure("DateOfDay, IsVariance", DateOfDay, True);
			
			FoundStrings = ChangedDays.FindRows(FilterParameters);
			
			If FoundStrings.Count() Then
				NewRow.IsVariance = True;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	DateByGraphs.Sort("WorkSchedule Asc, DateOfDay Asc");
	
EndProcedure

&AtServer
Procedure FillGraphData(YearNumber = Undefined)
	
	ChangedDays.Clear();
	
	Query = New Query;
	
	Query.SetParameter("Year", YearNumber);
	Query.SetParameter("Resource", Resource);
	
	Query.Text =
	"SELECT
	|	DeviationFromResourcesWorkSchedules.BeginTime AS BeginTime,
	|	DeviationFromResourcesWorkSchedules.WorkHours AS Duration,
	|	MONTH(DeviationFromResourcesWorkSchedules.BeginTime) AS MonthNumber,
	|	DeviationFromResourcesWorkSchedules.Year AS Year,
	|	CASE
	|		WHEN ENDOFPERIOD(DeviationFromResourcesWorkSchedules.EndTime, Day) = DeviationFromResourcesWorkSchedules.EndTime
	|			THEN BEGINOFPERIOD(DeviationFromResourcesWorkSchedules.EndTime, Day)
	|		ELSE DeviationFromResourcesWorkSchedules.EndTime
	|	END AS EndTime,
	|	TRUE AS Changed,
	|	TRUE AS IsVariance,
	|	DAY(DeviationFromResourcesWorkSchedules.Day) AS MonthDay,
	|	DeviationFromResourcesWorkSchedules.Day AS Date,
	|	DeviationFromResourcesWorkSchedules.BreakHours AS BreakHours
	|FROM
	|	InformationRegister.DeviationFromResourcesWorkSchedules AS DeviationFromResourcesWorkSchedules
	|WHERE
	|	DeviationFromResourcesWorkSchedules.EnterpriseResource = &Resource
	|	AND DeviationFromResourcesWorkSchedules.Year = &Year";
	
	QueryResult = Query.Execute().Select();
	
	While QueryResult.Next() Do
		
		NewRow = ChangedDays.Add();
		FillPropertyValues(NewRow, QueryResult);
		NewRow.DateOfDay = BegOfDay(QueryResult.BeginTime);
		
	EndDo;
	
	DeviationsTable = ChangedDays.Unload(,"DateOfDay, Duration");
	DeviationsTable.GroupBy("DateOfDay","Duration");
	
	For Each RowDeviation In DeviationsTable Do
		
		StringDayNumber = String(Day(RowDeviation.DateOfDay));
		
		NameFieldDay = NStr("en='Day';vi='Ngày'") + StringDayNumber;
		NameFieldChanged = NStr("en='Changed';vi='Thay đổi'")+StringDayNumber;
		
		RowGraphData = ScheduleData[Month(RowDeviation.DateOfDay) - 1];
		
		RowGraphData[NameFieldDay] = RowDeviation.Duration;
		RowGraphData.TotalHours = RowGraphData.TotalHours + RowDeviation.Duration;
		RowGraphData[NameFieldChanged] = True;
		
	EndDo;
	
	Query = New Query;
	
	DelimiterPacket = "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	TextPacket = 
	"SELECT
	|	WorkSchedules.BeginTime AS BeginTime,
	|	WorkSchedules.WorkHours AS Duration,
	|	MONTH(WorkSchedules.BeginTime) AS MonthNumber,
	|	WorkSchedules.Year AS Year,
	|	CASE
	|		WHEN ENDOFPERIOD(WorkSchedules.EndTime, DAY) = WorkSchedules.EndTime
	|			THEN BEGINOFPERIOD(WorkSchedules.EndTime, DAY)
	|		ELSE WorkSchedules.EndTime
	|	END AS EndTime,
	|	TRUE AS Changed,
	|	FALSE AS IsVariance,
	|	DAY(WorkSchedules.BeginTime) AS MonthDay,
	|	BEGINOFPERIOD(WorkSchedules.BeginTime, DAY) AS Date,
	|	WorkSchedules.BreakHours AS BreakHours
	|FROM
	|	InformationRegister.WorkSchedules AS WorkSchedules
	|WHERE
	|	WorkSchedules.Year = &Year
	|	AND WorkSchedules.FillTemplate = VALUE(Catalog.WorkTimeGraphsTemplates.EmptyRef)
	|	AND WorkSchedules.WorkSchedule = &WorkSchedule
	|	AND WorkSchedules.BeginTime >= &StartDate
	|	AND NOT BEGINOFPERIOD(WorkSchedules.BeginTime, DAY) IN
	|				(SELECT DISTINCT
	|					DeviationFromResourcesWorkSchedules.Day AS Day
	|				FROM
	|					InformationRegister.DeviationFromResourcesWorkSchedules AS DeviationFromResourcesWorkSchedules
	|				WHERE
	|					DeviationFromResourcesWorkSchedules.Year = &Year
	|					AND DeviationFromResourcesWorkSchedules.EnterpriseResource = &Resource)
	|	AND WorkSchedules.BeginTime < &EndDate
	|
	|ORDER BY
	|	MonthNumber,
	|	Date
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(WorkSchedules.WorkHours) AS Duration,
	|	MONTH(WorkSchedules.BeginTime) AS MonthNumber,
	|	WorkSchedules.Year AS Year,
	|	WorkSchedules.FillTemplate = VALUE(Catalog.WorkTimeGraphsTemplates.EmptyRef) AS Changed,
	|	DAY(WorkSchedules.BeginTime) AS MonthDay,
	|	WorkSchedules.CycleDayNumber AS CycleDayNumber,
	|	BEGINOFPERIOD(WorkSchedules.BeginTime, DAY) AS Date
	|FROM
	|	InformationRegister.WorkSchedules AS WorkSchedules
	|WHERE
	|	WorkSchedules.Year = &Year
	|	AND WorkSchedules.WorkSchedule = &WorkSchedule
	|	AND WorkSchedules.BeginTime >= &StartDate
	|	AND NOT BEGINOFPERIOD(WorkSchedules.BeginTime, DAY) IN
	|				(SELECT DISTINCT
	|					DeviationFromResourcesWorkSchedules.Day AS Day
	|				FROM
	|					InformationRegister.DeviationFromResourcesWorkSchedules AS DeviationFromResourcesWorkSchedules
	|				WHERE
	|					DeviationFromResourcesWorkSchedules.Year = &Year
	|					AND DeviationFromResourcesWorkSchedules.EnterpriseResource = &Resource)
	|	AND WorkSchedules.BeginTime < &EndDate
	|
	|GROUP BY
	|	WorkSchedules.Year,
	|	WorkSchedules.CycleDayNumber,
	|	WorkSchedules.FillTemplate = VALUE(Catalog.WorkTimeGraphsTemplates.EmptyRef),
	|	BEGINOFPERIOD(WorkSchedules.BeginTime, DAY),
	|	MONTH(WorkSchedules.BeginTime),
	|	DAY(WorkSchedules.BeginTime)
	|
	|ORDER BY
	|	MonthNumber,
	|	Date";
	
	QueryText = "";
	
	GraphQuantity = 1;
	
	If GraphWorkForYear.Count() = 1 Then
		
		Query.SetParameter("WorkSchedule", GraphWorkForYear[0].WorkSchedule);
		
		If ValueIsFilled(YearNumber) And Not Year(GraphWorkForYear[0].Period) = YearNumber Then
			Query.SetParameter("StartDate", BegOfYear(Date(YearNumber,1,1)));
			Query.SetParameter("EndDate", EndOfYear(Date(YearNumber,1,1)));
		Else
			Query.SetParameter("StartDate", GraphWorkForYear[0].Period);
			Query.SetParameter("EndDate", EndOfYear(GraphWorkForYear[0].Period));
		EndIf;
		
		Query.Text = TextPacket;
		
		GraphQuantity = GraphQuantity + 1;
		
	Else
		
		For Each GraphForYear In GraphWorkForYear Do
			
			PacketRedaction = "";
			
			GraphParameterName = "WorkSchedule"+String(GraphQuantity);
			NameParameterBeginPeriod = "StartDate"+String(GraphQuantity);
			NameParameterEndPeriod = "EndDate"+String(GraphQuantity);
			
			PacketRedaction = StrReplace(TextPacket, "&WorkSchedule", "&"+GraphParameterName);
			PacketRedaction = StrReplace(PacketRedaction, "&StartDate", "&"+NameParameterBeginPeriod);
			PacketRedaction = StrReplace(PacketRedaction, "&EndDate", "&"+NameParameterEndPeriod);
			
			QueryText = QueryText + PacketRedaction + DelimiterPacket;
			
			Query.SetParameter(GraphParameterName, GraphForYear.WorkSchedule);
			
			If ValueIsFilled(YearNumber) And Not Year(GraphForYear.Period) = YearNumber Then
				Query.SetParameter(NameParameterBeginPeriod, BegOfYear(Date(YearNumber,1,1)));
				
				EndOfPeriod = ?(GraphQuantity < GraphWorkForYear.Count(), GraphWorkForYear[GraphQuantity].Period
				, EndOfYear(GraphForYear.Period));
				
				Query.SetParameter(NameParameterEndPeriod, EndOfPeriod);
			Else
				
				Query.SetParameter(NameParameterBeginPeriod, GraphForYear.Period);
				
				EndOfPeriod = ?(GraphQuantity < GraphWorkForYear.Count(), GraphWorkForYear[GraphQuantity].Period
				, EndOfYear(GraphForYear.Period));
				
				Query.SetParameter(NameParameterEndPeriod, EndOfPeriod);
				
			EndIf;
			
			GraphQuantity = GraphQuantity + 1;
			
		EndDo;
		
		Query.Text = QueryText;
		
	EndIf;
	
	If Not ValueIsFilled(Query.Text) Then Return EndIf;
	
	Query.SetParameter("Year", YearNumber);
	Query.SetParameter("Resource", Resource);
	
	QueryBatch = Query.ExecuteBatch();
	
	PackagesCount = (GraphQuantity-1)*2;
	
	For GraphIndex = 1 To PackagesCount Do
		
		PackageNumber = GraphIndex-1;
		
		QueryResult = QueryBatch[PackageNumber].Select();
		
		If Not GraphIndex%2 = 0 Then
			
			While QueryResult.Next() Do
				
				NewRow = ChangedDays.Add();
				FillPropertyValues(NewRow, QueryResult);
				NewRow.DateOfDay = BegOfDay(QueryResult.BeginTime);
				
			EndDo;
			
			Continue;
			
		EndIf;
		
		While QueryResult.Next() Do
			
			StringDayNumber = String(QueryResult.MonthDay);
			
			NameFieldDay = NStr("en='Day';vi='Ngày'") + StringDayNumber;
			NameFieldCycleDay = "CycleDayNumber"+StringDayNumber;
			NameFieldChanged = NStr("en='Changed';vi='Thay đổi'")+StringDayNumber;
			
			RowGraphData = ScheduleData[QueryResult.MonthNumber - 1];
			
			RowGraphData[NameFieldDay] = QueryResult.Duration;
			RowGraphData[NameFieldCycleDay] = QueryResult.CycleDayNumber;
			RowGraphData.TotalHours = RowGraphData.TotalHours + QueryResult.Duration;
			RowGraphData[NameFieldChanged] = QueryResult.Changed;
			
		EndDo;
		
	EndDo;
	
	For Each DataRow In ScheduleData Do
		
		DataRow.DayHoursRepresentation = String(DataRow.TotalsDays) + " / " + String(DataRow.TotalHours);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateProductionGraphCalendar(OnFormOpening = False, YearNumber = Undefined)
	
	YearNumber = ?(Not YearNumber = Undefined, YearNumber, CurrentYearNumber);
	
	GraphManager = Catalogs.WorkSchedules;
	GraphManager.FillByProductionCalendarData(ScheduleData, YearNumber, True, True, OnFormOpening, BeginnigDate, ScheduleType,, Object);
	
	GraphQuantity = 1;
	
	For Each GraphForYear In GraphWorkForYear Do
		
		If Not ValueIsFilled(GraphForYear.BusinessCalendar) Then 
			GraphQuantity = GraphQuantity+1;
			Continue 
		EndIf;
		
		CalendarData = GraphManager.BusinessCalendarData(GraphForYear.BusinessCalendar, YearNumber);
		
		If Not CalendarData.Count() Then 
			GraphQuantity = GraphQuantity+1;
			Continue 
		EndIf;
		
		EndOfPeriod = ?(GraphQuantity < GraphWorkForYear.Count(), GraphWorkForYear[GraphQuantity].Period
		, EndOfYear(GraphForYear.Period));
		
		
		If Not Year(GraphForYear.Period) = YearNumber Then 
			MonthBegin = 1;
			MonthEnd = 12;
			BeginPeriodDayNumber = 1;
			EndPeriod = 31;
		Else
			MonthBegin = Month(GraphForYear.Period);
			MonthEnd = Month(EndOfPeriod);
			BeginPeriodDayNumber = Day(GraphForYear.Period);
			EndPeriod = Day(EndOfPeriod);
		EndIf;
		
		For CounterMonth = MonthBegin To MonthEnd Do
			
			CalendarRow = ScheduleData[CounterMonth-1];
			
			NumberOfDaysInMonth = Day(EndOfMonth(Date(YearNumber,CounterMonth, 1)));
			
			If CounterMonth = MonthEnd Then
				NumberOfDaysInMonth = EndPeriod
			Else
				NumberOfDaysInMonth = Day(EndOfMonth(Date(YearNumber,CounterMonth, 1)));
			EndIf;
			
			For DayNumber = BeginPeriodDayNumber To NumberOfDaysInMonth Do
				
				StringDayNumber = String(DayNumber);
				NameFieldDayKind = "DayKind"+StringDayNumber;
				
				DateOfDay = Date(YearNumber, CounterMonth, DayNumber);
				
				FilterParameters = New Structure("Date", DateOfDay);
				RowsProductionCalendar = CalendarData.FindRows(FilterParameters);
				RowProductionCalendar = RowsProductionCalendar[0];
				
				CalendarRow[NameFieldDayKind] = RowProductionCalendar.DayKind;
				
			EndDo;
			
			BeginPeriodDayNumber = 1;
			
		EndDo;
		
		GraphQuantity = GraphQuantity+1;
	EndDo;
	
EndProcedure

&AtClient
Procedure AfterQuestionClosingWriteGraph(Result, NotificationParameters) Export
	
	If Not NotificationParameters = Undefined Then
		YearForWriteNumber = ?(NotificationParameters.Direction<0, CurrentYearNumber-NotificationParameters.Direction
		, CurrentYearNumber-NotificationParameters.Direction);
	Else
		CurrentYearNumber = CurrentYearNumber
	EndIf;
	
	If Result = DialogReturnCode.No Then
		UpdateProductionGraphCalendar(True, CurrentYearNumber);
		ProcessGraphData(CurrentYearNumber);
		BeginnigDate = Date(CurrentYearNumber,1,1);
		Return;
	EndIf;
	
	WriteParameters = New Structure("CurrentYearNumber", YearForWriteNumber);
	
	Cancel = False;
	
	WriteDataInRegister(YearForWriteNumber, Cancel);
	
	If Cancel Then Return EndIf;
	
	BeginnigDate = Date(CurrentYearNumber,1,1);
	UpdateProductionGraphCalendar(True, CurrentYearNumber);
	ProcessGraphData(CurrentYearNumber);
	
EndProcedure

&AtClient
Procedure FixChangedPeriodOneDay(Result, AdditNotificationParameters) Export
	
	If Not Result = Undefined And Result.Property("Periods") Then
		
		CleanChangedFieldsDays(Result.DateOfDay);
		
		For Each PeriodString In Result.Periods Do
			
			NewRow = ChangedDays.Add();
			FillPropertyValues(NewRow, PeriodString);
			NewRow.DateOfDay = Result.DateOfDay;
			NewRow.Duration = PeriodString.Duration;
			NewRow.IsVariance = True;
			
			FilterParameters = New Structure("DateOfDay", NewRow.DateOfDay);
			FoundStrings = DateByGraphs.FindRows(FilterParameters);
			
			If FoundStrings.Count() Then
				FoundStrings[0].IsVariance = True;
			EndIf;
			
		EndDo;
		
		If Not Result.Periods.Count() Then
			If (ValueIsFilled(Result.BeginTime) Or ValueIsFilled(Result.EndTime)) Then
				
				NewRow = ChangedDays.Add();
				NewRow.DateOfDay = Result.DateOfDay;
				NewRow.BeginTime = Result.BeginTime;
				NewRow.EndTime = Result.EndTime;
				
				Duration = Round((Result.EndTime - Result.BeginTime)/3600, 2, RoundMode.Round15as20);
				HoursByDay = ?(Duration < 0, 24 + Duration, Duration)-Result.TimeBreak;
				
				NewRow.BreakHours = Result.TimeBreak;
				NewRow.Duration = HoursByDay;
				
				NewRow.IsVariance = True;
				
				FilterParameters = New Structure("DateOfDay", NewRow.DateOfDay);
				FoundStrings = DateByGraphs.FindRows(FilterParameters);
				
				If FoundStrings.Count() Then
					FoundStrings[0].IsVariance = True;
				EndIf;
				
			Else
				
				NewRow = ChangedDays.Add();
				NewRow.DateOfDay = Result.DateOfDay;
				NewRow.BreakHours = Result.TimeBreak;
				NewRow.Duration = Result.WorkingHours;
				
				NewRow.IsVariance = True;
				
				FilterParameters = New Structure("DateOfDay", NewRow.DateOfDay);
				FoundStrings = DateByGraphs.FindRows(FilterParameters);
				
				If FoundStrings.Count() Then
					FoundStrings[0].IsVariance = True;
				EndIf;
				
			EndIf;
		EndIf;
		
		HoursByDay = Result.WorkingHours;
		
		DataRow = ScheduleData[Month(Result.DateOfDay)-1];
		
		DataRow["Day"+String(AdditNotificationParameters.DayNumber)] = HoursByDay;
		DataRow["Changed"+String(AdditNotificationParameters.DayNumber)] = True;
		
		//ГрафикИзменен = Истина;
		
		CalculateWorkHours(DataRow.MonthNumber);
		
		WriteDataInRegister(CurrentYearNumber);
		
		DisplayTimetableSchedule(); 
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FixChangedPeriodSelectedDays(Result, AdditNotificationParameters) Export
	
	If Not Result = Undefined And Result.Property("Periods") Then
		
		For Each SelectedListDay In AdditNotificationParameters.ListDays Do
			
			SelectedDay = SelectedListDay.Value;
			
			CleanChangedFieldsDays(SelectedDay);
			
			For Each PeriodString In Result.Periods Do
				
				NewRow = ChangedDays.Add();
				FillPropertyValues(NewRow, PeriodString);
				NewRow.DateOfDay = SelectedDay;
				NewRow.Duration = PeriodString.Duration;
				NewRow.IsVariance = True;
				
				FilterParameters = New Structure("DateOfDay", NewRow.DateOfDay);
				FoundStrings = DateByGraphs.FindRows(FilterParameters);
				
				If FoundStrings.Count() Then
					FoundStrings[0].IsVariance = True;
				EndIf;
				
			EndDo;
			
			If Not Result.Periods.Count() Then
				If (ValueIsFilled(Result.BeginTime) Or ValueIsFilled(Result.EndTime)) Then
					
					NewRow = ChangedDays.Add();
					NewRow.DateOfDay = SelectedDay;
					NewRow.BeginTime = Result.BeginTime;
					NewRow.EndTime = Result.EndTime;
					
					Duration = Round((Result.EndTime - Result.BeginTime)/3600, 2, RoundMode.Round15as20);
					HoursByDay = ?(Duration < 0, 24 + Duration, Duration)-Result.TimeBreak;
					
					NewRow.BreakHours = Result.TimeBreak;
					NewRow.Duration = HoursByDay;
					NewRow.IsVariance = True;
					
					FilterParameters = New Structure("DateOfDay", NewRow.DateOfDay);
					FoundStrings = DateByGraphs.FindRows(FilterParameters);
					
					If FoundStrings.Count() Then
						FoundStrings[0].IsVariance = True;
					EndIf;
					
				Else
					
					NewRow = ChangedDays.Add();
					NewRow.DateOfDay = SelectedDay;
					NewRow.BreakHours = Result.TimeBreak;
					NewRow.Duration = Result.WorkingHours;
					NewRow.IsVariance = True;
					
					TotalDurationWorkDay = Result.TimeBreak + Result.WorkingHours;
					
					If Not TotalDurationWorkDay = 24 Then
						
						BeginTime = 28800;
						EndTime = BeginTime + (TotalDurationWorkDay)*60*60;
						
						If EndTime>=86400 Then
							BeginTime = Date(1,1,1) + (86400 - (TotalDurationWorkDay)*60*60);
							EndTime = Date(1,1,1);
						Else
							BeginTime = Date(1,1,1) + 28800;
							EndTime = BeginTime + (TotalDurationWorkDay)*60*60;
						EndIf;
						
						NewRow.BeginTime = BeginTime;
						NewRow.EndTime = EndTime;
						
					EndIf;
					
					FilterParameters = New Structure("DateOfDay", NewRow.DateOfDay);
					FoundStrings = DateByGraphs.FindRows(FilterParameters);
					
					If FoundStrings.Count() Then
						FoundStrings[0].IsVariance = True;
					EndIf;
					
				EndIf;
			EndIf;
			
			HoursByDay = Result.WorkingHours;
			
			If Not HoursByDay = 0 Then
				DataRow = ScheduleData[Month(SelectedDay)-1];
				
				DayNumber = Day(SelectedDay);
				
				DataRow["Day"+String(DayNumber)] = HoursByDay;
				DataRow["Changed"+String(DayNumber)] = True;
			EndIf;
			
			//ГрафикИзменен = Истина;
			
			CalculateWorkHours(DataRow.MonthNumber);
			
		EndDo;
		
	EndIf;
	
	WriteDataInRegister(CurrentYearNumber);
	
	DisplayTimetableSchedule();
	
EndProcedure

&AtClient
Procedure CalculateWorkHours(MonthNumber)
	
	If MonthNumber = 0 Then Return EndIf;
	
	NumberOfDaysInMonth = Day(EndOfMonth(Date(CurrentYearNumber,MonthNumber, 1)));
	
	WorkHoursPerMonth = 0;
	
	For DayNumber = 1 To NumberOfDaysInMonth Do
		NameFieldDay = NStr("en='Day';vi='Ngày'") + String(DayNumber);
		
		WorkHoursPerMonth = WorkHoursPerMonth + ScheduleData[MonthNumber-1][NameFieldDay];
	EndDo;
	
	ScheduleData[MonthNumber-1].TotalHours = WorkHoursPerMonth;
	ScheduleData[MonthNumber-1].DayHoursRepresentation = String(NumberOfDaysInMonth) + " / " + String(WorkHoursPerMonth);
	
EndProcedure

&AtClient
Procedure CleanChangedFieldsDays(DateOfDay)
	
	FilterParameters = New Structure("DateOfDay", DateOfDay);
	RowsChangedDays = ChangedDays.FindRows(FilterParameters);
	
	For Each RowChangedDays In RowsChangedDays Do
		ChangedDays.Delete(RowChangedDays);
	EndDo;
	
EndProcedure

&AtServer
Procedure WriteDataInRegister(YearWrite, Cancel = False)
	
	BeginTransaction();
	
	RecordSet = InformationRegisters.DeviationFromResourcesWorkSchedules.CreateRecordSet();
	RecordSet.Filter.EnterpriseResource.Set(Resource);
	RecordSet.Filter.Year.Set(YearWrite);
	RecordSet.Write();
	
	If Not ScheduleData.Count() Then
		CommitTransaction();
		Return
	EndIf;
	
	FilterParameters = New Structure("IsVariance", True);
	
	FoundStrings = ChangedDays.FindRows(FilterParameters);
	
	For Each FoundString In FoundStrings Do
		
		TimeBeginSec = FoundString.BeginTime-Date(1,1,1);
		TimeFinishSec = FoundString.EndTime-Date(1,1,1);
		
		If TimeBeginSec = 0 And TimeFinishSec = 0
			And FoundString.Duration+FoundString.BreakHours < 24 Then
			
			TimeBeginSec = 28800;
			TimeFinishSec = TimeBeginSec+FoundString.Duration*3600+FoundString.BreakHours*3600;
			
			If TimeFinishSec > 86400 Then
				TimeBeginSec = TimeBeginSec-(TimeFinishSec-86400);
				TimeFinishSec = 0;
			EndIf;
			
		EndIf;
		
		NewRecord = RecordSet.Add();
		NewRecord.EnterpriseResource = Resource;
		NewRecord.Year = YearWrite;
		NewRecord.Day = FoundString.DateOfDay;
		NewRecord.BeginTime = FoundString.DateOfDay+TimeBeginSec;
		NewRecord.EndTime = FoundString.DateOfDay+TimeFinishSec;
		
		If BegOfDay(NewRecord.BeginTime) = NewRecord.EndTime Then
			NewRecord.EndTime = NewRecord.EndTime + 86399;
		EndIf;
		
		NewRecord.WorkHours = FoundString.Duration;
		NewRecord.BreakHours = FoundString.BreakHours;
		
	EndDo;
	
	Try
		RecordSet.Write();
		CommitTransaction();
	Except
		TextOfMessage = NStr("en='При записи графика произошла ошибка!"
"Дополнительное описание: %AdditionalDetails%';ru='При записи графика произошла ошибка!"
"Дополнительное описание: %AdditionalDetails%';vi='Đã xảy ra lỗi khi ghi biểu đồ!"
"Mô tả bổ sung: %AdditionalDetails% '");
		TextOfMessage = StrReplace(TextOfMessage, "%AdditionalDetails%", ErrorDescription());
		CommonUse.MessageToUser(TextOfMessage);
		RollbackTransaction();
		Cancel = True;
		Return;
	EndTry;
	
EndProcedure

&AtServer
Procedure AddTabularSection(NameTSReceiver, TPSource, WorkSchedule)
	
	For Each TSRow In TPSource Do
		
		NewRow = Object[NameTSReceiver].Add();
		NewRow.WorkSchedule = WorkSchedule;
		FillPropertyValues(NewRow, TSRow);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateGraphData(WorkSchedule, ArrayProseccedGraphs)
	
	If Not ArrayProseccedGraphs.Find(WorkSchedule) = Undefined Then Return EndIf;
	
	AddTabularSection("TemplateByYear", WorkSchedule.TemplateByYear, WorkSchedule);
	AddTabularSection("WorkSchedule", WorkSchedule.WorkSchedule, WorkSchedule);
	AddTabularSection("Breaks", WorkSchedule.Breaks, WorkSchedule);
	AddTabularSection("AdditionalFillingSettings", WorkSchedule.AdditionalFillingSettings, WorkSchedule);
	AddTabularSection("AdditionalFillingSettingsPeriods", WorkSchedule.AdditionalFillingSettingsPeriods, WorkSchedule);
	AddTabularSection("GraphPeriods", WorkSchedule.GraphPeriods, WorkSchedule)
	
EndProcedure

&AtClient
Procedure SetTimetableEnd(Response,Parameters) Export
	
	If Response = DialogReturnCode.Yes Then
		UpdateEndYear = True
	ElsIf Response = DialogReturnCode.No Then
		UpdateEndYear = False;
	Else
		Return;
	EndIf;
	
	OpenForm("Catalog.WorkSchedules.ChoiceForm", New Structure("CurrentRow", GraphForInstalation), ThisForm);
	
EndProcedure

&AtServer
Procedure SetTimetableAtServer()
	
	If Not ValueIsFilled(GraphDateInstalation) Or Not ValueIsFilled(GraphForInstalation) Then
		Return
	EndIf;
	
	BeginTransaction();
	
	FilterParameters = New Structure("EnterpriseResource", Resource);
	
	DeletePeriodEnd = ?(UpdateEndYear, EndOfYear(GraphDateInstalation), GraphDateInstalation);
	
	Selection = InformationRegisters.ResourcesWorkSchedules.Select(GraphDateInstalation, DeletePeriodEnd, FilterParameters);
	
	While Selection.Next() Do
		Selection.GetRecordManager().Delete();
	EndDo;
	
	RecordManager = InformationRegisters.ResourcesWorkSchedules.CreateRecordManager();
	
	RecordManager.EnterpriseResource = Resource;
	RecordManager.Period = GraphDateInstalation;
	RecordManager.WorkSchedule = GraphForInstalation;
	
	Try
		RecordManager.Write();
	Except
		RollbackTransaction();
		Raise
	EndTry;
	
	CommitTransaction();
	
	FillGraphAttributesData(CurrentYearNumber);
	
EndProcedure

&AtClient
Procedure GeneratePeriodPresentation()
	
	SelectedAreas = Items.TimetableSchedule.GetSelectedAreas();
	DatesArray = New Array;
	GraphListHref.Clear();
	
	For Each CurArea In SelectedAreas Do
		
		If TypeOf(CurArea) <> Type("SpreadsheetDocumentRange") Then
			Continue;
		EndIf;
		For curRow = CurArea.Top To CurArea.Bottom Do
			For CurColumn = CurArea.Left To CurArea.Right Do
				If CurColumn >= 3 And CurColumn <= 33 And curRow >= 2 And curRow <= 13 Then
					Try
						DateOfDay = Date(CurrentYearNumber, curRow - 1, CurColumn - 2, 0, 0, 0);
						DatesArray.Add(DateOfDay);
					Except
						Continue;
					EndTry;
				EndIf;
			EndDo
		EndDo
	EndDo;
	
	GraphDescription = GraphDesription(DatesArray);
	
	Items.SetSchedule.Enabled = ?(DatesArray.Count() = 1, True, False);
	
	ButtonsEnabled = ?(DatesArray.Count(), True, False);
	
	Items.FielGraphRepresetation.Hyperlink = ButtonsEnabled;
	
	Items.GroupSubmenu.Enabled = ButtonsEnabled;
	Items.GroupActions.Enabled = ButtonsEnabled;
	Items.ScheduleByGraphContexBarGroupChange.Enabled = ButtonsEnabled;
	
EndProcedure

&AtClient
Function GraphDesription(DatesArray)
	
	If Not DatesArray.Count() Then
		Return "<chose cell calendar>"
	EndIf;
	
	PresentationRow = "";
	
	For Each ListElement In GraphList Do
		
		FilterParameters = New Structure("WorkSchedule", ListElement.Value);
		RowsByGraphs = DateByGraphs.FindRows(FilterParameters);
		
		IntervalBegin = "";
		IntervalEnd = "";
		IntervalView = "";
		
		IsIntervalByGraph = False;
		
		For Each RowByGraph In RowsByGraphs Do
			
			If Not DatesArray.Find(RowByGraph.DateOfDay) = Undefined Then
				
				If Not ValueIsFilled(IntervalBegin) Then
					IntervalBegin = RowByGraph.DateOfDay;
				EndIf;
				
				IntervalEnd = RowByGraph.DateOfDay;
				
				IsIntervalByGraph = True;
				
			EndIf;
		EndDo;
		
		If Not IsIntervalByGraph Then Continue EndIf;
		
		GraphListHref.Add(ListElement.Value);
		
		If IntervalBegin = IntervalEnd Then
			IntervalView = " ("+Format(IntervalBegin,"DF=dd.MM.yyyy")+").";
		Else
			IntervalView = " ("+Format(IntervalBegin,"DF=dd.MM.yyyy")+":"+Format(IntervalEnd,"DF=dd.MM.yyyy")+");";
		EndIf;
		
		
		PresentationRow = PresentationRow + String(ListElement.Value)+IntervalView;
		
	EndDo;
	
	Return ?(Not ValueIsFilled(PresentationRow), "<on selected date graph notavailable>", PresentationRow);
	
EndFunction

&AtClient
Procedure AfterGraphChoice(SelectedItem, ListOfParameters) Export
	If Not SelectedItem = Undefined Then
		FormParameters = New Structure;
		FormParameters.Insert("Key", SelectedItem.Value);
		
		OpenForm("Catalog.WorkSchedules.ObjectForm", FormParameters,ThisForm,,,,, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

&AtServer
Procedure CleanDeviationsAtServer()
	
	RecordSet = InformationRegisters.DeviationFromResourcesWorkSchedules.CreateRecordSet();
	RecordSet.Filter.Year.Set(CurrentYearNumber);
	RecordSet.Filter.EnterpriseResource.Set(Resource);
	RecordSet.Write();
	
	FillGraphAttributesData(CurrentYearNumber);
	
EndProcedure

&AtServer
Procedure CleanDeviationsForPeriodAtServer(DatesArray)
	
	BeginTransaction();
	
	For Each DateOfDay In DatesArray Do
		
		RecordSet = InformationRegisters.DeviationFromResourcesWorkSchedules.CreateRecordSet();
		RecordSet.Filter.Year.Set(CurrentYearNumber);
		RecordSet.Filter.EnterpriseResource.Set(Resource);
		RecordSet.Filter.Day.Set(DateOfDay);
		
		Try
			RecordSet.Write();
		Except
			RollbackTransaction();
			Raise;
		EndTry
	EndDo;
	
	CommitTransaction();
	
	FillGraphAttributesData(CurrentYearNumber);
	
EndProcedure

&AtClient
Procedure AfterChoiceFormMenu(SelectedItem, Parameters) Export
	
	If SelectedItem = Undefined Then Return EndIf;
	
	If SelectedItem.Value = "Edit" Then
		ChangeScheduleClient();
	ElsIf SelectedItem.Value = "Clear" Then
		CleanScheduleClientInteractive();
	ElsIf SelectedItem.Value = "Delete rejections" Then
		CleanDeviationsForPeriodClient();
	ElsIf SelectedItem.Value = "Delete all rejections" Then
		CleanDeviationsAtServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure CleanDeviationsForPeriodClient()
	
	SelectedAreas = Items.TimetableSchedule.GetSelectedAreas();
	
	IsProcessedAreas = False;
	
	For Each CurArea In SelectedAreas Do
		
		If TypeOf(CurArea) <> Type("SpreadsheetDocumentRange") Then
			Continue;
		EndIf;
		
		DatesArray = New Array;
		
		For curRow = CurArea.Top To CurArea.Bottom Do
			For CurColumn = CurArea.Left To CurArea.Right Do
				If CurColumn >= 3 And CurColumn <= 33 And curRow >= 2 And curRow <= 13 Then
					Try
						DateOfDay = Date(CurrentYearNumber, curRow - 1, CurColumn - 2, 0, 0, 0);
						
						DayNumber = Day(DateOfDay);
						MonthNumber = Month(DateOfDay);
						
						FilterParameters = New Structure("MonthNumber",MonthNumber);
						RowsOfData = ScheduleData.FindRows(FilterParameters);
						
						If Not RowsOfData.Count() Then Return EndIf;
						
						DataRow = RowsOfData[0];
						Changed = DataRow["Changed"+DayNumber];
						
						If Not Changed Then Continue EndIf;
						
					Except
						Continue;
					EndTry;
					
					DatesArray.Add(DateOfDay);
					
				EndIf;
			EndDo;
		EndDo;
		
	EndDo;
	
	If DatesArray.Count() Then
		CleanDeviationsForPeriodAtServer(DatesArray);
	EndIf

EndProcedure

&AtClient
Procedure CleanScheduleClientInteractive()
	SelectedAreas = Items.TimetableSchedule.GetSelectedAreas();
	
	IsProcessedAreas = False;
	
	For Each CurArea In SelectedAreas Do
		
		If TypeOf(CurArea) <> Type("SpreadsheetDocumentRange") Then
			Continue;
		EndIf;
		
		For curRow = CurArea.Top To CurArea.Bottom Do
			For CurColumn = CurArea.Left To CurArea.Right Do
				If CurColumn >= 3 And CurColumn <= 33 And curRow >= 2 And curRow <= 13 Then
					Try
						DateOfDay = Date(CurrentYearNumber, curRow - 1, CurColumn - 2, 0, 0, 0);
					Except
						Continue;
					EndTry;
					
					DayNumber = Day(DateOfDay);
					MonthNumber = Month(DateOfDay);
					
					DataRow = ScheduleData[Month(DateOfDay)-1];
					
					If DataRow["Day"+String(DayNumber)] = 0 Then Continue EndIf;
					
					CleanChangedFieldsDays(DateOfDay);
					
					DataRow["Day"+String(DayNumber)] = 0;
					DataRow["Changed"+String(DayNumber)] = True;
					
					NewRow = ChangedDays.Add();
					NewRow.Duration = 0;
					NewRow.DateOfDay = DateOfDay;
					NewRow.IsVariance = True;
					
					FilterParameters = New Structure("DateOfDay", NewRow.DateOfDay);
					FoundStrings = DateByGraphs.FindRows(FilterParameters);
					
					If FoundStrings.Count() Then
						FoundStrings[0].IsVariance = True;
					EndIf;
					
					IsProcessedAreas = True;
					
					CalculateWorkHours(MonthNumber);
				EndIf;
			EndDo;
		EndDo;
		
	EndDo;
	
	If IsProcessedAreas Then
		WriteDataInRegister(CurrentYearNumber);
		DisplayTimetableSchedule();
	EndIf;
EndProcedure

&AtClient
Procedure ChangeScheduleClient()
	
	SelectedAreas = Items.TimetableSchedule.GetSelectedAreas();
	
	If SelectedAreas.Count() = 1 
		And SelectedAreas[0].Top = SelectedAreas[0].Bottom And SelectedAreas[0].Left = SelectedAreas[0].Right Then
		
		CurArea = SelectedAreas[0];
		
		If TypeOf(CurArea) <> Type("SpreadsheetDocumentRange") Then
			Return;
		EndIf;
		
		Try
			DateOfDay = Date(CurrentYearNumber, CurArea.Bottom-1, CurArea.Right-2, 0, 0, 0);
		Except
			
			Message = New UserMessage;
			Message.Text = NStr("en='Select day or period calendar In table!';vi='Chọn lịch ngày hoặc lịch Trong bảng!'");
			Message.Message();
			
			Return;
		EndTry;
		
		DayNumber = Day(DateOfDay);
		MonthNumber = Month(DateOfDay);
		
		FilterParameters = New Structure("MonthNumber",MonthNumber);
		
		RowsOfData = ScheduleData.FindRows(FilterParameters);
		
		If Not RowsOfData.Count() Then Return EndIf;
		
		DataRow = RowsOfData[0];
		
		CycleDayNumber = DataRow["CycleDayNumber"+DayNumber];
		Changed = DataRow["Changed"+DayNumber];
		WorkingHours = DataRow["Day"+DayNumber];
		
		AdditNotificationParameters = New Structure("DayNumber", DayNumber);
		
		NotifyDescription = New NotifyDescription(
		"FixChangedPeriodOneDay",
		ThisObject,
		AdditNotificationParameters);
		
		OpenParameters = New Structure;
		OpenParameters.Insert("DateOfDay", DateOfDay);
		OpenParameters.Insert("CycleDayNumber", CycleDayNumber);
		
		WorkSchedule = EmptyRefToGraph;
		
		For Each RowGraphForYear In GraphWorkForYear Do
			
			If DateOfDay>=RowGraphForYear.Period Then
				WorkSchedule = RowGraphForYear.WorkSchedule;
			EndIf;
			
		EndDo;
		
		OpenParameters.Insert("Ref", WorkSchedule);
		OpenParameters.Insert("Changed", Changed);
		OpenParameters.Insert("ChangedDays", ChangedDays);
		OpenParameters.Insert("WorkingHours", WorkingHours);
		OpenParameters.Insert("SelectedInterval", False);
		
		OpenForm("Catalog.WorkSchedules.Form.FormChangeSchedule", OpenParameters,,,,, NotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
		
		Return
	EndIf;
	
	ListDays = New ValueList;
	MapTransferedDataGraphs = New Map();
	WorkHours = 0;
	
	For Each CurArea In SelectedAreas Do
		
		For curRow = CurArea.Top To CurArea.Bottom Do
			For CurColumn = CurArea.Left To CurArea.Right Do
				If CurColumn >= 3 And CurColumn <= 33 And curRow >= 2 And curRow <= 13 Then
					Try
						DateOfDay = Date(CurrentYearNumber, curRow - 1, CurColumn - 2, 0, 0, 0);
					Except
						Continue;
					EndTry;
					
					DayNumber = Day(DateOfDay);
					MonthNumber = Month(DateOfDay);
					
					FilterParameters = New Structure("MonthNumber",MonthNumber);
					
					RowsOfData = ScheduleData.FindRows(FilterParameters);
					DataRow = RowsOfData[0];
					
					Changed = DataRow["Changed"+DayNumber];
					CycleDayNumber = DataRow["CycleDayNumber"+DayNumber];
					
					ListDays.Add(DateOfDay, String(CycleDayNumber), Changed);
					WorkHours = DataRow["Day"+DayNumber];
					
					GraphDateFilterParameters = New Structure("DateOfDay",DateOfDay);
					
					RowsMapDateGraph = DateByGraphs.FindRows(GraphDateFilterParameters);
					
					If RowsMapDateGraph.Count() Then
						
						MapTransferedDataGraphs.Insert(DateOfDay, RowsMapDateGraph[0].WorkSchedule);
						
					EndIf;
					
				EndIf;
			EndDo;
		EndDo;
		
	EndDo;
	
	If Not ListDays.Count() Then Return EndIf;
	
	AdditNotificationParameters = New Structure("ListDays", ListDays);
	
	NotifyDescription = New NotifyDescription(
	"FixChangedPeriodSelectedDays",
	ThisObject,
	AdditNotificationParameters);
	
	OpenParameters = New Structure;
	OpenParameters.Insert("DateOfDay", Date(1,1,1));
	OpenParameters.Insert("Object", Object);
	OpenParameters.Insert("CycleDayNumber", 0);
	OpenParameters.Insert("Changed", False);
	OpenParameters.Insert("ChangedDays", ChangedDays);
	OpenParameters.Insert("WorkingHours", WorkHours);
	OpenParameters.Insert("SelectedInterval", True);
	OpenParameters.Insert("ListDays", ListDays);
	OpenParameters.Insert("MapTransferedDataGraphs", MapTransferedDataGraphs);
	
	OpenForm("Catalog.WorkSchedules.Form.FormChangeSchedule", OpenParameters,,,,, NotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion










