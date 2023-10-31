
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ChangingMonthNumber = 0;
	CurrentYearNumber = Year(CurrentSessionDate());
	
	Items.BeginnigDate.Visible = ?(ScheduleType = Enums.WorkScheduleTypes.ShiftWork, True, False);
	
	If Parameters.Key.IsEmpty() And Not ValueIsFilled(Parameters.CopyingValue) Then
		
		BeginnigDate = Date(CurrentYearNumber,1,1);
		
		ScheduleType = Enums.WorkScheduleTypes.ShiftWork;
		
		Object.BusinessCalendar = BusinessCalendar();
		
		UpdateProductionGraphCalendar(True);
		
	Else
		
		Color = Object.Ref.Color.Get();
		
		FilterParameters = New Structure("Year", CurrentYearNumber);
		RowTemplateByYear = Object.TemplateByYear.FindRows(FilterParameters);
		
		If RowTemplateByYear.Count() Then
			TemplateGraphFill = RowTemplateByYear[0].TemplateGraphFill;
			BeginnigDate = RowTemplateByYear[0].BeginnigDate;
		EndIf;
		
		If Not ValueIsFilled(BeginnigDate) Then
			BeginnigDate = Date(CurrentYearNumber,1,1);
		EndIf;
		
		If ValueIsFilled(Parameters.CopyingValue)
			And ValueIsFilled(Object.BusinessCalendar)
			And ValueIsFilled(TemplateGraphFill) Then
			
			ЗаполнитьГрафикНаСервере();
			
			Items.BeginnigDate.Visible = ?(ScheduleType = Enums.WorkScheduleTypes.ShiftWork, True, False);
			
		EndIf;
		
		If ValueIsFilled(Object.Ref) Then
			Color = Object.Ref.Color.Get();
		EndIf;
		
	EndIf;
	
	DisplayTimetableSchedule();
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	If ValueIsFilled(TemplateGraphFill) Then
		
		YearNumber = ?(WriteParameters.Property("CurrentYearNumber") And ValueIsFilled(WriteParameters.CurrentYearNumber)
		, WriteParameters.CurrentYearNumber, CurrentYearNumber);
		
		FilterParameters = New Structure("Year", YearNumber);
		RowTemplateByYear = Object.TemplateByYear.FindRows(FilterParameters);
		
		If Not RowTemplateByYear.Count() Then
			NewRow = Object.TemplateByYear.Add();
			NewRow.Year = YearNumber;
			NewRow.TemplateGraphFill = TemplateGraphFill;
			NewRow.BeginnigDate = BeginnigDate;
			NewRow.ScheduleType = ScheduleType;
			
		Else
			RowTemplateByYear[0].TemplateGraphFill = TemplateGraphFill;
			RowTemplateByYear[0].BeginnigDate = BeginnigDate;
			RowTemplateByYear[0].ScheduleType = ScheduleType;
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	CurrentObject.Color = New ValueStorage(Color);
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Cancel Then Return EndIf;
	
	YearNumber = ?(WriteParameters.Property("CurrentYearNumber") And ValueIsFilled(WriteParameters.CurrentYearNumber)
	, WriteParameters.CurrentYearNumber, CurrentYearNumber);
	
	WriteDataInRegister(YearNumber, Cancel, CurrentObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	CurrentYearNumber = Year(CurrentSessionDate());
	
	UpdateProductionGraphCalendar(True);
	
	ProcessGraphData();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	#If MobileClient Then
		Items.ПолеЦвет.MaxWidth = 45; 
	#EndIf
EndProcedure

#EndRegion

#Region FormItemEventsHandlers

&AtClient
Procedure FillTemplateStartChoice(Item, ChoiceData, StandardProcessing)
	
	If Not ValueIsFilled(Object.BusinessCalendar) Then
		TextOfMessage = NStr("en='Не указан производственный календарь';ru='Не указан производственный календарь';vi='Không có lịch sản xuất được chỉ định'");
		ShowMessageBox(Undefined, TextOfMessage);
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure FillTemplateOnChange(Item)
	
	FillByTemplate();
	
	If ScheduleData.Count() Then
		ThisForm.Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure BusinessCalendarOnChange(Item)
	
	UpdateProductionGraphCalendar();
	
	If ScheduleData.Count() Then
		ThisForm.Modified = True;
	EndIf;
	
	DisplayTimetableSchedule();
	
EndProcedure

&AtClient
Procedure CurrentYearNumberTuning(Item, Direction, StandardProcessing)
	
	StandardProcessing = False;
	
	ClearMessages();
	
	If ThisForm.Modified And ScheduleData.Count() Then
		Mode = QuestionDialogMode.YesNo;
		
		If Not ValueIsFilled(Object.Description)
			Then
			Message = New UserMessage();
			Message.Text = NStr("en='Поле наименование не заполнено!';ru='Поле наименование не заполнено!';vi='Trường tên trống!'");
			Message.Field = "Object.Description";
			Message.SetData(ThisForm);
			Message.Message();
			//СтандартнаяОбработка = Ложь;
			Return;
		EndIf;
		
		NotificationParameters = New Structure("Direction", Direction);
		
		Notification = New NotifyDescription("AfterQuestionClosingWriteGraph", ThisForm, NotificationParameters);
		
		QuestionText = NStr("en='Данные графика за %1% год изменены. Сохранить данные графика?';ru='Данные графика за %1% год изменены. Сохранить данные графика?';vi='Dữ liệu biểu đồ cho %1% của năm được thay đổi. Lưu dữ liệu lịch?'");
		QuestionText = StrReplace(QuestionText,"%1%", String(CurrentYearNumber));
		
		ShowQueryBox(Notification, QuestionText, Mode, 0);
	Else
		BeginnigDate = Date(CurrentYearNumber + Direction,1,1);
		ProcessGraphData(CurrentYearNumber + Direction);
	EndIf;
	
	CurrentYearNumber = CurrentYearNumber + Direction;
	
EndProcedure

&AtClient
Procedure CurrentYearNumberOnChange(Item)
	
	ClearMessages();
	
	If ThisForm.Modified And ScheduleData.Count() Then
		Mode = QuestionDialogMode.YesNo;
		
		If Not ValueIsFilled(Object.Description)
			Then
			Message = New UserMessage();
			Message.Text = NStr("en='Поле наименование не заполнено!';ru='Поле наименование не заполнено!';vi='Trường tên trống!'");
			Message.Field = "Object.Description";
			Message.SetData(ThisForm);
			Message.Message();
			StandardProcessing = False;
			Return;
		EndIf;
		
		NotificationParameters = New Structure("Direction", "ЭтоСобытиеПриИзменении");
		
		Notification = New NotifyDescription("AfterQuestionClosingWriteGraph", ThisForm, NotificationParameters);
		
		QuestionText = NStr("en='Данные графика за %1% год изменены. Сохранить данные графика?';ru='Данные графика за %1% год изменены. Сохранить данные графика?';vi='Dữ liệu biểu đồ cho %1% của năm được thay đổi. Lưu dữ liệu lịch?'");
		QuestionText = StrReplace(QuestionText,"%1%", String(CurrentYearNumber));
		
		ShowQueryBox(Notification, QuestionText, Mode, 0);
	Else
		BeginnigDate = Date(CurrentYearNumber,1,1);
		ProcessGraphData(CurrentYearNumber);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeginnigDateOnChange(Item)
	
	If ValueIsFilled(BeginnigDate) Then
		
		If Not Year(BeginnigDate) = CurrentYearNumber Then
			
			Message = New UserMessage();
			Message.Text = NStr("en='Год даты отсчета не совпадает с годом графика!';ru='Год даты отсчета не совпадает с годом графика!';vi='Năm của ngày đếm ngược không trùng với năm của lịch trình!'");
			Message.Field = "BeginnigDate";
			Message.SetData(ThisForm);
			Message.Message();
			
			BeginnigDate = Date(CurrentYearNumber,1,1);
			
			Return;
			
		EndIf;
		
		ДеньДатыОтсчета = Day(BeginnigDate);
		МесяцДатыОтсчета = Month(BeginnigDate);
		
		For CounterMonth = 1 To МесяцДатыОтсчета Do
			
			LineNumber = CounterMonth - 1;
			
			NumberOfDaysInMonth = ScheduleData[LineNumber].NumberOfDaysInMonth;
			
			For DayNumber = 1 To NumberOfDaysInMonth Do
				
				If МесяцДатыОтсчета = CounterMonth
					And DayNumber = ДеньДатыОтсчета Then
					Break
				EndIf;
				
				ScheduleData[LineNumber]["Day"+String(DayNumber)] = 0;
				
			EndDo;
		EndDo;
	Else
		BeginnigDate = Date(CurrentYearNumber,1,1);
	EndIf;
	
	DisplayTimetableSchedule();
	
	ThisForm.Modified = True;
	
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
		DisplayTimetableSchedule();
		ThisForm.Modified = True;
	EndIf;
EndProcedure

&AtClient
Function DaysHaveBreaks(ListDays)
	
	For Each ListElement In ListDays Do
		
		DateOfDay = ListElement.Value;
		
		DayNumber = Day(DateOfDay);
		
		If ListElement.Check Then
			FilterParameters = New Structure("DateOfDay", DateOfDay);
			RowsChangedDays = ChangedDays.FindRows(FilterParameters);
			
			If RowsChangedDays.Count() > 1 Then
				Return True
			EndIf;
			
			Continue
		EndIf;
		
		FilterParameters = New Structure("CycleDayNumber", Number(ListElement.Presentation));
		RowsCycleDays = Object.GraphPeriods.FindRows(FilterParameters);
		
		If RowsCycleDays.Count() > 1 Then
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
				CleanScheduleClient(True);
				DataRow["Day"+DayNumber] = 0;
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
				DataRow["Changed"+DayNumber] = True;
				
				//Продолжить;
				
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
		FilterParameters = New Structure("CycleDayNumber", CycleDayNumber);
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
			
			If RowDay.EndTime>EndTime Then
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
		OpenParameters.Insert("ErrorText", NStr("en='Boundaries periods output for boundaries wirk day. When edit schedule will updated current.';vi='Kết quả thời gian ranh giới cho ngày làm việc ranh giới. Khi chỉnh sửa lịch trình sẽ cập nhật hiện tại.';"));
		
		OpenForm("Catalog.WorkSchedules.Form.FormChangeSchedule", OpenParameters,,,,, NotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
		
		Return
	EndIf;
	
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
		
		If (Not ValueIsFilled(NewFieldValue) Or NewFieldValue = "0") And Not ValueIsFilled(PreviousFieldValue) Then
			CurrentCycleArea.Text = "";
			Continue
		EndIf;
		
		If (Not ValueIsFilled(NewFieldValue) Or NewFieldValue = "0") Then
			If ValueIsFilled(PreviousFieldValue) Then
				If ListElement.Check Then
					CleanChangedFieldsDays(DateOfDay);
				EndIf;
				CleanScheduleClient(True);
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
			
			IsProcessedAreas = True;
			
			Continue
		EndIf;
		
		CycleDayNumber = Number(ListElement.Presentation);
		FilterParameters = New Structure("CycleDayNumber", CycleDayNumber);
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
			
			IndexPeriod = IndexPeriod + 1;
		EndDo;
		
		DataRow["Changed"+DayNumber] = True;
		
		IsProcessedAreas = True;
		
		CalculateWorkHours(MonthNumber);
		
	EndDo;
		
EndProcedure

&AtClient
Procedure TimetableScheduleOnActivate(Item)
	
	SelectedAreas = Items.TimetableSchedule.GetSelectedAreas();
	
	ЕстьОбластиСДатами = False;
	
	For Each CurArea In SelectedAreas Do
		
		If TypeOf(CurArea) <> Type("SpreadsheetDocumentRange") Then
			Continue;
		EndIf;
		
		For curRow = CurArea.Top To CurArea.Bottom Do
			For CurColumn = CurArea.Left To CurArea.Right Do
				If CurColumn >= 3 And CurColumn <= 33 And curRow >= 2 And curRow <= 13 Then
					Try
						DateOfDay = Date(CurrentYearNumber, curRow - 1, CurColumn - 2, 0, 0, 0);
						ЕстьОбластиСДатами = True;
						Break;
					Except
						Continue;
					EndTry;
				EndIf
			EndDo
		EndDo;
	EndDo;
	
	Items.ScheduleByGraphContexBarGroupChange.Enabled = ЕстьОбластиСДатами;
	Items.GroupSubmenu.Enabled = ЕстьОбластиСДатами;
	Items.ГруппаРедактированияТабДокумента.Enabled = ЕстьОбластиСДатами;
	
EndProcedure

&AtClient
Procedure TimetableScheduleSelection(Item, Area, StandardProcessing)
	
	#If Not MobileClient Then
		Return;
	#EndIf
	
	StandardProcessing = False;
	
	NotificationParameters = New Structure;
	
	List = New ValueList;
	List.Add("Edit",,False, PictureLib.Change);
	List.Add("Clear",,False,PictureLib.Clear);
	Notification = New NotifyDescription("AfterChoiceFormMenu",ThisForm,NotificationParameters);
	ShowChooseFromMenu(Notification, List, Items.TimetableSchedule);
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure ChangeSchedule(Command)
	
	ИзменитьРасписаниеПериода();
	
EndProcedure

&AtClient
Procedure UpdateGraph(Command)
	
	If Not ValueIsFilled(Object.BusinessCalendar) Then
		TextOfMessage = NStr("en='Не указан производственный календарь';ru='Не указан производственный календарь';vi='Không có lịch sản xuất được chỉ định'");
		ShowMessageBox(Undefined, TextOfMessage);
		Return;
	EndIf;
	
	ЗаполнитьГрафикНаСервере(True);
	
EndProcedure

&AtClient
Procedure ОбновитьПоПроизводственномуКалендарю(Command)
	
	If Not ValueIsFilled(Object.BusinessCalendar) Then Return EndIf;
	
	UpdateProductionGraphCalendar();
	
	If ScheduleData.Count() Then
		ThisForm.Modified = True;
	EndIf;
	
	DisplayTimetableSchedule();
	
EndProcedure

&AtClient
Procedure ОбновитьПоШаблону(Command)
	
	ОбновитьГрафикПоШаблону();
	
EndProcedure

&AtClient
Procedure CleanSchedule(Command)
	CleanScheduleClient();
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure DisplayTimetableSchedule(YearNumber = Undefined)
	
	YearNumber = ?(ValueIsFilled(YearNumber), YearNumber, CurrentYearNumber);
	
	TimetableSchedule.Clear();
	
	If Not ScheduleData.Count() Then Return EndIf;
	
	TimetableSchedule.FixedLeft = 2;
	TimetableSchedule.FixedTop = 1;
	
	TimetableScheduleTemplate = Catalogs.WorkSchedules.GetTemplate("WorkTimetable");
	
	TemplateArea = TimetableScheduleTemplate.GetArea("Header");
	TimetableSchedule.Put(TemplateArea);
	
	TemplateArea = TimetableScheduleTemplate.GetArea("Calendar");
	TimetableSchedule.Put(TemplateArea);
	
	PotentialAbilitiesBackgroundColor = StyleColors.PotentialAbilitiesBackgroundColor;
	NonWorkingTimeDayOff = StyleColors.NonWorkingTimeDayOff;
	InaccessibleDataColor = StyleColors.InaccessibleDataColor;
	
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
				Area.BackColor = InaccessibleDataColor;
				Area.Text = "X";
				
			Else
				
				DateOfDay = Date(YearNumber, MonthNumber, DayNumber, 0, 0, 0);
				StringDayNumber = String(DayNumber);
				
				ColumnDayKind = "DayKind"+StringDayNumber;
				ColumnDay = "Day"+ StringDayNumber; 
				
				If ValueIsFilled(BeginnigDate) And DateOfDay < BeginnigDate Then
					
					Area.Protection = True;
					Area.Text = "";
					
				Else
					
					// Раскраска выходных дней.
					If DataRow[ColumnDayKind] = Enums.BusinessCalendarDayKinds.Sunday
						Or DataRow[ColumnDayKind] = Enums.BusinessCalendarDayKinds.Saturday
						Or DataRow[ColumnDayKind] = Enums.BusinessCalendarDayKinds.Holiday
						Or DataRow[ColumnDayKind] = Enums.BusinessCalendarDayKinds.Preholiday Then
						Area.BackColor = NonWorkingTimeDayOff;
					Else
						Area.BackColor = PotentialAbilitiesBackgroundColor;
					EndIf;
					
					Area.Text = DataRow[ColumnDay];
					Area.Protection = False;
				EndIf;
				
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

&AtServer
Function BusinessCalendar()
	
	Query = New Query;
	
	Query.Text =
	"SELECT DISTINCT
	|	BusinessCalendars.Ref AS Ref
	|FROM
	|	Catalog.BusinessCalendars AS BusinessCalendars
	|WHERE
	|	NOT BusinessCalendars.DeletionMark";
	
	Result = Query.Execute().Unload();
	
	If Result.Count() = 1 Then
		Return Result[0].Ref;
	Else
		Return Catalogs.BusinessCalendars.EmptyRef();
	EndIf;
	
EndFunction

&AtServer
Procedure ЗаполнитьГрафикНаСервере(ИзменениеГодаИлиДатыОтсчета = False)
	
	ScheduleData.Clear();
	
	ДатаОтсчетаДляЗаполнения = BeginnigDate;
	
	If Not ValueIsFilled(ДатаОтсчетаДляЗаполнения) And Object.TemplateByYear.Count() Then
		Object.TemplateByYear.Sort("Year Desc");
		For Each СтрокаШаблонаПоГоду In Object.TemplateByYear Do
			If ValueIsFilled(СтрокаШаблонаПоГоду.BeginnigDate) Then
				ДатаОтсчетаДляЗаполнения = СтрокаШаблонаПоГоду.BeginnigDate;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If ИзменениеГодаИлиДатыОтсчета Then
		GraphManager = Catalogs.WorkSchedules;
		GraphManager.FillByProductionCalendarData(ScheduleData, CurrentYearNumber,,,,ДатаОтсчетаДляЗаполнения, ScheduleType, ChangedDays, Object);
		Return
	EndIf;
	
	Object.WorkSchedule.Load(TemplateGraphFill.WorkSchedule.Unload());
	Object.GraphPeriods.Load(TemplateGraphFill.Periods.Unload());
	Object.Breaks.Load(TemplateGraphFill.Breaks.Unload());
	Object.AdditionalFillingSettings.Load(TemplateGraphFill.AdditionalFillingSettings.Unload());
	Object.AdditionalFillingSettingsPeriods.Load(TemplateGraphFill.AdditionalFillingSettingsPeriods.Unload());
	Object.AccountHolidays = TemplateGraphFill.AccountHolidays;
	
	FilterParameters = New Structure("Year", CurrentYearNumber);
	RowTemplateByYear = Object.TemplateByYear.FindRows(FilterParameters);
	
	If Not RowTemplateByYear.Count() Then
		NewRow = Object.TemplateByYear.Add();
		NewRow.Year = CurrentYearNumber;
		NewRow.TemplateGraphFill = TemplateGraphFill;
		NewRow.BeginnigDate = BeginnigDate;
		NewRow.ScheduleType = ?(Not ValueIsFilled(TemplateGraphFill.ScheduleType)
		, Enums.WorkScheduleTypes.ShiftWork, TemplateGraphFill.ScheduleType);
		
		ScheduleType = NewRow.ScheduleType;
	Else
		RowTemplateByYear[0].TemplateGraphFill = TemplateGraphFill;
		RowTemplateByYear[0].BeginnigDate = BeginnigDate;
		RowTemplateByYear[0].ScheduleType = ?(Not ValueIsFilled(TemplateGraphFill.ScheduleType)
		, Enums.WorkScheduleTypes.ShiftWork, TemplateGraphFill.ScheduleType);
		
		ScheduleType = RowTemplateByYear[0].ScheduleType;
	EndIf;
	
	GraphManager = Catalogs.WorkSchedules;
	GraphManager.FillByProductionCalendarData(ScheduleData, CurrentYearNumber,,,,ДатаОтсчетаДляЗаполнения, ScheduleType, ChangedDays, Object);
	
	Items.BeginnigDate.Visible = ?(ScheduleType = Enums.WorkScheduleTypes.ShiftWork, True, False);
	
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
	
	If Not ScheduleData.Count() Then 
		DisplayTimetableSchedule(YearNumber);
		Return
	EndIf;
	
	ПодготовитьИзмененныеДни(YearNumber);
	FillGraphData(YearNumber);
	
	Items.BeginnigDate.Visible = ?(ScheduleType = Enums.WorkScheduleTypes.ShiftWork, True, False);
	
	DisplayTimetableSchedule(YearNumber);
	
EndProcedure

&AtServer
Procedure FillGraphData(YearNumber = Undefined)
	
	Query = New Query;
	
	Query.SetParameter("WorkSchedule", Object.Ref);
	Query.SetParameter("Year", YearNumber);
	
	Query.Text =
	"SELECT
	|	SUM(WorkSchedules.WorkHours) AS Duration,
	|	WorkSchedules.CycleDayNumber AS CycleDayNumber,
	|	DAY(WorkSchedules.BeginTime) AS MonthDay,
	|	MONTH(WorkSchedules.BeginTime) AS MonthNumber,
	|	WorkSchedules.FillTemplate = VALUE(Catalog.WorkTimeGraphsTemplates.EmptyRef) AS Changed,
	|	BEGINOFPERIOD(WorkSchedules.BeginTime, DAY) AS BeginTime
	|FROM
	|	InformationRegister.WorkSchedules AS WorkSchedules
	|WHERE
	|	WorkSchedules.WorkSchedule = &WorkSchedule
	|	AND WorkSchedules.Year = &Year
	|
	|GROUP BY
	|	WorkSchedules.CycleDayNumber,
	|	DAY(WorkSchedules.BeginTime),
	|	MONTH(WorkSchedules.BeginTime),
	|	WorkSchedules.FillTemplate = VALUE(Catalog.WorkTimeGraphsTemplates.EmptyRef),
	|	BEGINOFPERIOD(WorkSchedules.BeginTime, DAY)
	|
	|ORDER BY
	|	MonthNumber,
	|	MonthDay,
	|	CycleDayNumber";
	
	QueryResult = Query.Execute().Select();
	
	While QueryResult.Next() Do
		
		StringDayNumber = String(QueryResult.MonthDay);
		
		NameFieldDay = NStr("en='Day';vi='Ngày'") + StringDayNumber;
		NameFieldCycleDay = "CycleDayNumber"+StringDayNumber;
		NameFieldChanged = "Changed"+StringDayNumber;
		
		RowGraphData = ScheduleData[QueryResult.MonthNumber - 1];
		
		RowGraphData[NameFieldDay] = QueryResult.Duration;
		RowGraphData[NameFieldCycleDay] = QueryResult.CycleDayNumber;
		RowGraphData[NameFieldChanged] = QueryResult.Changed;
		RowGraphData.TotalHours = RowGraphData.TotalHours + QueryResult.Duration;
		
	EndDo;
	
	For Each DataRow In ScheduleData Do
		
		DataRow.DayHoursRepresentation = String(DataRow.TotalsDays) + " / " + String(DataRow.TotalHours);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ПодготовитьИзмененныеДни(YearNumber = Undefined)
	
	ChangedDays.Clear();
	
	Query = New Query;
	
	Query.SetParameter("WorkSchedule", Object.Ref);
	Query.SetParameter("Year", YearNumber);
	
	Query.Text =
	"SELECT
	|	WorkSchedules.WorkHours AS Duration,
	|	MONTH(WorkSchedules.BeginTime) AS MonthNumber,
	|	WorkSchedules.FillTemplate = VALUE(Catalog.WorkTimeGraphsTemplates.EmptyRef) AS Changed,
	|	WorkSchedules.BreakHours AS BreakHours,
	|	WorkSchedules.Year AS Year,
	|	WorkSchedules.CycleDayNumber AS CycleDayNumber,
	|	DAY(WorkSchedules.BeginTime) AS MonthDay,
	|	WorkSchedules.BeginTime AS BeginTime,
	|	CASE
	|		WHEN ENDOFPERIOD(WorkSchedules.EndTime, DAY) = WorkSchedules.EndTime
	|			THEN BEGINOFPERIOD(WorkSchedules.EndTime, DAY)
	|		ELSE WorkSchedules.EndTime
	|	END AS EndTime
	|FROM
	|	InformationRegister.WorkSchedules AS WorkSchedules
	|WHERE
	|	WorkSchedules.WorkSchedule = &WorkSchedule
	|	AND WorkSchedules.Year = &Year
	|	AND WorkSchedules.FillTemplate = VALUE(Catalog.WorkTimeGraphsTemplates.EmptyRef)
	|
	|ORDER BY
	|	MonthNumber";
	
	QueryResult = Query.Execute().Select();
	
	While QueryResult.Next() Do
		
		NewRow = ChangedDays.Add();
		FillPropertyValues(NewRow, QueryResult);
		NewRow.DateOfDay = BegOfDay(QueryResult.BeginTime);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure FillByTemplate()
	
	Object.AdditionalFillingSettings.Clear();
	Object.AdditionalFillingSettingsPeriods.Clear();
	ChangedDays.Clear();
	Object.GraphPeriods.Clear();
	Object.AccountHolidays = False;
	ScheduleType = Undefined;
	
	BeginnigDate = ?(Not ValueIsFilled(BeginnigDate), Date(CurrentYearNumber,1,1), BeginnigDate);
	
	If Not ValueIsFilled(TemplateGraphFill) Then
		
		Mode = QuestionDialogMode.YesNo;
		
		NotificationParameters = New Structure();
		Notification = New NotifyDescription("ПослеЗакрытияВопросаОчисткаГрафика", ThisForm, NotificationParameters);
		
		QuestionText = NStr("en='Очистить данные графика за %1% год?';ru='Очистить данные графика за %1% год?';vi='Xóa dữ liệu đồ thị cho %1% năm?'");
		QuestionText = StrReplace(QuestionText,"%1%", String(CurrentYearNumber));
		
		FilterParameters = New Structure("Year", CurrentYearNumber);
		RowTemplateByYear = Object.TemplateByYear.FindRows(FilterParameters);
		
		If Not RowTemplateByYear.Count() Then
			NewRow = Object.TemplateByYear.Add();
			NewRow.Year = CurrentYearNumber;
			NewRow.TemplateGraphFill = TemplateGraphFill;
			NewRow.BeginnigDate = BeginnigDate;
			NewRow.ScheduleType = PredefinedValue("Enum.WorkScheduleTypes.ShiftWork");
		Else
			RowTemplateByYear[0].TemplateGraphFill = TemplateGraphFill;
			RowTemplateByYear[0].BeginnigDate = BeginnigDate;
			RowTemplateByYear[0].ScheduleType = PredefinedValue("Enum.WorkScheduleTypes.ShiftWork");
		EndIf;
		
		ScheduleType = PredefinedValue("Enum.WorkScheduleTypes.ShiftWork");
		
		ShowQueryBox(Notification, QuestionText, Mode, 0);
		
		Return
	EndIf;
	
	If Not ПроизводственныйКалендарьЗаполнен(Object.BusinessCalendar, CurrentYearNumber) Then
		
		TextOfMessage = NStr("en='Для заполнения по шаблону необходио заполнить производственный календарь на %YearCalendar% год.';ru='Для заполнения по шаблону необходио заполнить производственный календарь на %YearCalendar% год.';vi='Để điền vào mẫu, cần điền lịch sản xuất cho %YearCalendar% năm.'");
		TextOfMessage = StrReplace(TextOfMessage, "%YearCalendar%", String(CurrentYearNumber));
		CommonUseClientServer.MessageToUser(TextOfMessage);
		
		Return;
	EndIf;
	
	ЗаполнитьГрафикНаСервере();
	
	If Not ScheduleType = PredefinedValue("Enum.WorkScheduleTypes.ShiftWork") Then
		BeginnigDate = Date(CurrentYearNumber,1,1);
		Items.BeginnigDate.Visible = False;
	Else
		Items.BeginnigDate.Visible = True;
	EndIf;
	
	DisplayTimetableSchedule();
	
EndProcedure

&AtClient
Procedure ПослеЗакрытияВопросаОчисткаГрафика(Result, NotificationParameters) Export
	
	If Result = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ЗаполнитьГрафикНаСервере();
	
	UpdateProductionGraphCalendar(True,,True);
	
	DisplayTimetableSchedule();
	
EndProcedure

&AtServer
Procedure UpdateProductionGraphCalendar(OnFormOpening = False, YearNumber = Undefined, ЭтоОчисткаГрафика = False)
	
	YearNumber = ?(Not YearNumber = Undefined, YearNumber, CurrentYearNumber);
	
	GraphManager = Catalogs.WorkSchedules;
	
	If ValueIsFilled(Object.BusinessCalendar) Then
		
		If ПроизводственныйКалендарьЗаполнен(Object.BusinessCalendar, YearNumber) Then
			GraphManager.FillByProductionCalendarData(ScheduleData, YearNumber, True,,OnFormOpening, BeginnigDate, ScheduleType,,Object);
		Else
			GraphManager.FillByProductionCalendarData(ScheduleData, YearNumber, True, True, OnFormOpening, BeginnigDate, ScheduleType,,Object);
			
			If Not ЭтоОчисткаГрафика Then
				TextOfMessage = NStr("en='Не заполнен производственный календарь на %YearCalendar% год.';ru='Не заполнен производственный календарь на %YearCalendar% год.';vi='Lịch sản xuất cho %YearCalendari% năm không được điền.'");
				TextOfMessage = StrReplace(TextOfMessage, "%YearCalendar%", String(YearNumber));
				CommonUse.MessageToUser(TextOfMessage);
			EndIf;
			
		EndIf;
		
	Else
		GraphManager.FillByProductionCalendarData(ScheduleData, YearNumber, True, True, OnFormOpening, BeginnigDate, ScheduleType,,Object);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterQuestionClosingWriteGraph(Result, NotificationParameters) Export
	
	If Not NotificationParameters.Direction = "ЭтоСобытиеПриИзменении" Then
		YearForWriteNumber = ?(NotificationParameters.Direction<0, CurrentYearNumber-NotificationParameters.Direction
		, CurrentYearNumber-NotificationParameters.Direction);
	EndIf;
	
	If Result = DialogReturnCode.No Then
		ProcessGraphData(CurrentYearNumber);
		BeginnigDate = Date(CurrentYearNumber,1,1);
		ThisForm.Modified = False;
		Return;
	EndIf;
	
	WriteParameters = New Structure("CurrentYearNumber", YearForWriteNumber);
	
	ThisForm.Write(WriteParameters);
	
	BeginnigDate = Date(CurrentYearNumber,1,1);
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
				
			Else
				
				NewRow = ChangedDays.Add();
				NewRow.DateOfDay = Result.DateOfDay;
				NewRow.BreakHours = Result.TimeBreak;
				NewRow.Duration = HoursByDay;
				
			EndIf;
		EndIf;
		
		HoursByDay = Result.WorkingHours;
		
		If Not HoursByDay = 0 Then
			
			DataRow = ScheduleData[Month(Result.DateOfDay)-1];
			
			DataRow["Day"+String(AdditNotificationParameters.DayNumber)] = HoursByDay;
			DataRow["Changed"+String(AdditNotificationParameters.DayNumber)] = True;
		EndIf;
		
		ThisForm.Modified = True;
		
		CalculateWorkHours(DataRow.MonthNumber);
		
		DisplayTimetableSchedule(); 
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FixChangedPeriodSelectedDays(Result, AdditNotificationParameters) Export
	
	
	If Not Result = Undefined And Result.Property("Periods") Then
		
		For Each SelectedDay In AdditNotificationParameters.ListDays Do
			
			CleanChangedFieldsDays(SelectedDay.Value);
			
			For Each PeriodString In Result.Periods Do
				
				NewRow = ChangedDays.Add();
				FillPropertyValues(NewRow, PeriodString);
				NewRow.DateOfDay = SelectedDay.Value;
				NewRow.Duration = PeriodString.Duration;
				
			EndDo;
			
			If Not Result.Periods.Count() Then
				If (ValueIsFilled(Result.BeginTime) Or ValueIsFilled(Result.EndTime)) Then
					
					NewRow = ChangedDays.Add();
					NewRow.DateOfDay = SelectedDay.Value;
					NewRow.BeginTime = Result.BeginTime;
					NewRow.EndTime = Result.EndTime;
					
					Duration = Round((Result.EndTime - Result.BeginTime)/3600, 2, RoundMode.Round15as20);
					HoursByDay = ?(Duration < 0, 24 + Duration, Duration)-Result.TimeBreak;
					
					NewRow.BreakHours = Result.TimeBreak;
					NewRow.Duration = HoursByDay;
					
				Else
					
					NewRow = ChangedDays.Add();
					NewRow.DateOfDay = SelectedDay.Value;
					NewRow.BreakHours = Result.TimeBreak;
					NewRow.Duration = Result.WorkingHours;
					
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
					
				EndIf;
			EndIf;
			
			HoursByDay = Result.WorkingHours;
			
			If Not HoursByDay = 0 Then
				DataRow = ScheduleData[Month(SelectedDay.Value)-1];
				
				DayNumber = Day(SelectedDay.Value);
				
				DataRow["Day"+String(DayNumber)] = HoursByDay;
				DataRow["Changed"+String(DayNumber)] = True;
			EndIf;
			
			ThisForm.Modified = True;
			
			CalculateWorkHours(DataRow.MonthNumber);
			
		EndDo;
		
	EndIf;
	
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
Procedure WriteDataInRegister(YearWrite, Cancel = False, CurrentObject)
	
	If Object.NotValid Then
		RecordSet = InformationRegisters.WorkSchedules.CreateRecordSet();
		RecordSet.Filter.WorkSchedule.Set(CurrentObject.Ref);
		RecordSet.Write();
		Return
	EndIf;
	
	BeginTransaction();
	
	RecordSet = InformationRegisters.WorkSchedules.CreateRecordSet();
	RecordSet.Filter.WorkSchedule.Set(CurrentObject.Ref);
	RecordSet.Filter.Year.Set(YearWrite);
	RecordSet.Write();
	
	If Not ScheduleData.Count() Then
		CommitTransaction();
		Return
	EndIf;
	
	For Each DataRow In ScheduleData Do
		
		For DayNumber = 1 To DataRow.NumberOfDaysInMonth Do
			
			If Not ValueIsFilled(DataRow["Day"+DayNumber]) Then
				Continue
			EndIf;
			
			ManualInput = DataRow["Changed"+DayNumber];
			DateOfDay = Date(YearWrite, DataRow.MonthNumber, DayNumber);
			CycleDayNumber = DataRow["CycleDayNumber"+DayNumber];
			
			If DateOfDay<BeginnigDate Then Continue EndIf;
			
			If ManualInput Then
				
				FilterParameters = New Structure("DateOfDay", DateOfDay);
				FoundStrings = ChangedDays.FindRows(FilterParameters);
				
				If FoundStrings.Count() Then
					
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
						NewRecord.Year = YearWrite;
						NewRecord.BeginTime = DateOfDay+TimeBeginSec;
						NewRecord.EndTime = DateOfDay+TimeFinishSec;
						
						If BegOfDay(NewRecord.BeginTime) = NewRecord.EndTime Then
							NewRecord.EndTime = NewRecord.EndTime + 86399;
						EndIf;
						
						NewRecord.WorkSchedule = CurrentObject.Ref;
						NewRecord.FillTemplate = Undefined;
						NewRecord.WorkHours = FoundString.Duration;
						NewRecord.BreakHours = FoundString.BreakHours;
						
					EndDo;
					
					Continue;
					
				Else
					TimeBeginSec = 28800;
					WorkHours = DataRow["Day"+DayNumber];
					TimeFinishSec = TimeBeginSec+WorkHours*3600;
					
					If TimeFinishSec > 86400 Then
						TimeBeginSec = TimeBeginSec-(TimeFinishSec-86400);
						TimeFinishSec = 0;
					EndIf;
					
					NewRecord = RecordSet.Add();
					NewRecord.Year = YearWrite;
					NewRecord.BeginTime = DateOfDay+TimeBeginSec;
					NewRecord.EndTime = DateOfDay+TimeFinishSec;
					
					If BegOfDay(NewRecord.BeginTime) = NewRecord.EndTime Then
						NewRecord.EndTime = NewRecord.EndTime + 86399;
					EndIf;
					
					NewRecord.WorkSchedule = CurrentObject.Ref;
					NewRecord.FillTemplate = Undefined;
					NewRecord.WorkHours = WorkHours;
					
					Continue;
					
				EndIf;
				
			EndIf;
			
			If CycleDayNumber = 0 Then Continue EndIf;
			
			FilterParameters = New Structure("CycleDayNumber", CycleDayNumber);
			FoundStrings = CurrentObject.GraphPeriods.FindRows(FilterParameters);
			
			For Each FoundString In FoundStrings Do
				
				TimeBeginSec = FoundString.BeginTime - Date(1,1,1);
				TimeFinishSec = FoundString.EndTime - Date(1,1,1);
				
				If TimeBeginSec = 0 And TimeFinishSec = 0
					And FoundString.Duration + FoundString.BreakHours<24 Then
					
					TimeBeginSec = 28800;
					TimeFinishSec = TimeBeginSec+FoundString.Duration*3600+FoundString.BreakHours*3600;
					
					If TimeFinishSec > 86400 Then
						TimeBeginSec = TimeBeginSec-(TimeFinishSec-86400);
						TimeFinishSec = 0;
					EndIf;
					
				EndIf;
				
				NewRecord = RecordSet.Add();
				NewRecord.Year = YearWrite;
				NewRecord.BeginTime = DateOfDay+TimeBeginSec;
				NewRecord.EndTime = DateOfDay+TimeFinishSec;
				
				If BegOfDay(NewRecord.BeginTime) = NewRecord.EndTime Then
					NewRecord.EndTime = NewRecord.EndTime + 86399;
				EndIf;
				
				NewRecord.WorkSchedule = CurrentObject.Ref;
				NewRecord.FillTemplate = TemplateGraphFill;
				NewRecord.WorkHours = FoundString.Duration;
				NewRecord.BreakHours = FoundString.BreakHours;
				NewRecord.CycleDayNumber = FoundString.CycleDayNumber;
				
			EndDo;
			
		EndDo
		
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

&AtClient
Procedure ОбновитьГрафикПоШаблону()
	
	ClearMessages();
	
	BeginnigDate = ?(Not ValueIsFilled(BeginnigDate), Date(CurrentYearNumber,1,1), BeginnigDate);
	
	If Not ValueIsFilled(TemplateGraphFill) Then Return EndIf;
	
	If Not ValueIsFilled(Object.BusinessCalendar) Then
		
		Message = New UserMessage();
		Message.Text = NStr("en='Для заполнения по шаблону, необходимо указать производственный календарь!';ru='Для заполнения по шаблону, необходимо указать производственный календарь!';vi='Để điền vào mẫu, cần chỉ định lịch sản xuất!'");
		Message.Field = "Object.BusinessCalendar";
		Message.SetData(ThisForm);
		Message.Message();
		
		Return
		
	EndIf;
	
	If ГрафикНеЗаполнен() Then
		
		FillByTemplate();
		
		If ScheduleData.Count() Then
			ThisForm.Modified = True;
		EndIf;
		
	Else
		
		Mode = QuestionDialogMode.YesNo;
		
		NotificationParameters = New Structure();
		Notification = New NotifyDescription("ПослеЗакрытияВопросаОбновитьГрафик", ThisForm, NotificationParameters);
		
		QuestionText = NStr("en='После обновления, данные графика будут перезаполнены. Продолжить?';ru='После обновления, данные графика будут перезаполнены. Продолжить?';vi='Sau khi cập nhật, dữ liệu lịch sẽ được bổ sung. Tiếp tục?'");
		
		ShowQueryBox(Notification, QuestionText, Mode, 0);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ПослеЗакрытияВопросаОбновитьГрафик(Result, NotificationParameters) Export
	
	If Result = DialogReturnCode.No Then
		Return;
	EndIf;
	
	FillByTemplate();
	
	If ScheduleData.Count() Then
		ThisForm.Modified = True;
	EndIf;
EndProcedure

&AtClient
Function ГрафикНеЗаполнен()
	
	For Each DataRow In ScheduleData Do
		
		If Not DataRow.TotalHours = 0 Then
			Return False
		EndIf;
		
	EndDo;
	
	Return True;
	
EndFunction

&AtClient
Procedure CleanScheduleClient(IsProcessedAreas = False)
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
					
					IsProcessedAreas = True;
					
					CalculateWorkHours(MonthNumber);
				EndIf;
			EndDo;
		EndDo;
		
	EndDo;
	
	If IsProcessedAreas Then
		ThisForm.Modified = True;
		DisplayTimetableSchedule();
	EndIf;
	
EndProcedure

&AtServer
Function ПроизводственныйКалендарьЗаполнен(BusinessCalendar, YearNumber) Export
	
	Query = New Query;
	
	Query.SetParameter("BusinessCalendar",	BusinessCalendar);
	Query.SetParameter("CurrentYear",	YearNumber);
	Query.Text =
	"SELECT
	|	BusinessCalendarData.Date,
	|	BusinessCalendarData.DayKind,
	|	BusinessCalendarData.DestinationDate
	|FROM
	|	InformationRegister.BusinessCalendarData AS BusinessCalendarData
	|WHERE
	|	BusinessCalendarData.Year = &CurrentYear
	|	AND BusinessCalendarData.BusinessCalendar = &BusinessCalendar";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

&AtClient
Procedure ИзменитьРасписаниеПериода()
	
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
			Message.Text = NStr("en='Select day or period calendar In table!';vi='Chọn lịch ngày hoặc lịch Trong bảng!';");
			Message.DataKey = Object.Ref;
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
		OpenParameters.Insert("Object", Object);
		OpenParameters.Insert("CycleDayNumber", CycleDayNumber);
		OpenParameters.Insert("Changed", Changed);
		OpenParameters.Insert("ChangedDays", ChangedDays);
		OpenParameters.Insert("WorkingHours", WorkingHours);
		OpenParameters.Insert("SelectedInterval", False);
		
		OpenForm("Catalog.WorkSchedules.Form.FormChangeSchedule", OpenParameters,,,,, NotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
		
		Return
	EndIf;
	
	ListDays = New ValueList;
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
	
	OpenForm("Catalog.WorkSchedules.Form.FormChangeSchedule", OpenParameters,,,,, NotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AfterChoiceFormMenu(SelectedItem, Parameters) Export
	
	If SelectedItem = Undefined Then Return EndIf;
	
	If SelectedItem.Value = "Edit" Then
		ИзменитьРасписаниеПериода();
	Else
		CleanScheduleClient();
	EndIf;
	
EndProcedure

#EndRegion

