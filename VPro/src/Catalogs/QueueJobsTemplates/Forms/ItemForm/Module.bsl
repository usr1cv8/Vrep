#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then // Return if the form for analysis is received.
		Return;
	EndIf;

	If Object.Ref.IsEmpty() Then
		Schedule = New JobSchedule;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	ID = Object.Ref.UUID();
	
	Schedule = CurrentObject.Schedule.Get();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.Schedule = New ValueStorage(Schedule);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	ID = Object.Ref.UUID();
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure OpenScheduleTasks(Command)
	
	Dialog = New ScheduledJobDialog(Schedule);
	Dialog.Show(New NotifyDescription("OpenScheduleEnd", ThisObject));
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtClient
Procedure OpenScheduleEnd(NewSchedule, CurrentData) Export

	If NewSchedule = Undefined Then
		Return;
	EndIf;
	
	Schedule = NewSchedule;
	LockFormDataForEdit();
	Modified = True;
	
	ShowUserNotification(NStr("en='Replanning';ru='Перепланирование';vi='Lập lại kế hoạch'"), , NStr("en='New schedule will be"
"considered at the following task"
"performance by template or update IB version';ru='Новое расписание будет учтено при"
"следующем выполнении задания по "
"шаблону или обновлении версии ИБ';vi='Lịch biểu mới sẽ bị mất khi thực hiện "
"nhiệm vụ lần sau theokhuôn mẫu "
"hoặc cập nhật phiên bản CSTT'"));
	
EndProcedure

#EndRegion