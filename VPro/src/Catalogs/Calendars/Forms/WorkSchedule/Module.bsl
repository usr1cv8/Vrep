
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then // Return if the form for analysis is received.
		Return;
	EndIf;
	
	DailySchedule = Parameters.WorkSchedule;
	
	For Each DetailsOfInterval IN DailySchedule Do
		FillPropertyValues(WorkSchedule.Add(), DetailsOfInterval);
	EndDo;
	WorkSchedule.Sort("BeginTime");
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	Notification = New NotifyDescription("ChooseAndClose", ThisObject);
	CommonUseClient.ShowFormClosingConfirmation(Notification, Cancel);
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure OK(Command)
	
	ChooseAndClose();
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Modified = False;
	NotifyChoice(Undefined);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// FORM ITEMS EVENTS HANDLERS

&AtClient
Procedure WorkScheduleOnEditEnd(Item, NewRow, CancelEdit)
		
	If CancelEdit Then
		Return;
	EndIf;
	
	WorkSchedulesClientServer.RestoreOrderRowsCollectionsAfterEditing(WorkSchedule, "BeginTime", Item.CurrentData);
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtClient
Function DailySchedule()
	
	Cancel = False;
	
	DailySchedule = New Array;
	
	EndOfDay = Undefined;
	
	For Each TimetableString IN WorkSchedule Do
		RowIndex = WorkSchedule.IndexOf(TimetableString);
		If TimetableString.BeginTime > TimetableString.EndTime 
			AND ValueIsFilled(TimetableString.EndTime) Then
			CommonUseClientServer.MessageToUser(
				NStr("en='Start time is greater than the end time.';ru='Время начала больше времени окончания';vi='Thời gian bắt đầu lớn hơn thời gian kết thúc'"), ,
				StringFunctionsClientServer.SubstituteParametersInString("WorkSchedule[%1].EndTime", RowIndex), ,
				Cancel);
		EndIf;
		If TimetableString.BeginTime = TimetableString.EndTime Then
			CommonUseClientServer.MessageToUser(
				NStr("en='Interval duration is not specified';ru='Длительность интервала не определена';vi='Thời gian của khoảng thời gian chưa xác định'"), ,
				StringFunctionsClientServer.SubstituteParametersInString("WorkSchedule[%1].EndTime", RowIndex), ,
				Cancel);
		EndIf;
		If EndOfDay <> Undefined Then
			If EndOfDay > TimetableString.BeginTime 
				Or Not ValueIsFilled(EndOfDay) Then
				CommonUseClientServer.MessageToUser(
					NStr("en='Overlapping intervals are detected';ru='Обнаружены пересекающиеся интервалы';vi='Tìm thấy khoản thời gian chồng chéo'"), ,
					StringFunctionsClientServer.SubstituteParametersInString("WorkSchedule[%1].BeginTime", RowIndex), ,
					Cancel);
			EndIf;
		EndIf;
		EndOfDay = TimetableString.EndTime;
		DailySchedule.Add(New Structure("BeginTime, EndTime", TimetableString.BeginTime, TimetableString.EndTime));
	EndDo;
	
	If Cancel Then
		Return Undefined;
	EndIf;
	
	Return DailySchedule;
	
EndFunction

&AtClient
Procedure ChooseAndClose(Result = Undefined, AdditionalParameters = Undefined) Export
	
	DailySchedule = DailySchedule();
	If DailySchedule = Undefined Then
		Return;
	EndIf;
	
	Modified = False;
	NotifyChoice(New Structure("WorkSchedule", DailySchedule));
	
EndProcedure

#EndRegion
