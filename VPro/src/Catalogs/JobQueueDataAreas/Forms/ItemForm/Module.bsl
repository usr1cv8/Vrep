#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest") Then // Return if the form for analysis is received.
		Return;
	EndIf;

	If Not Users.InfobaseUserWithFullAccess(, True) Then
		ReadOnly = True;
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		SetPresentationSchedule(ThisObject);
		MethodParameters = CommonUse.ValueToXMLString(New Array);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	ID = Object.Ref.UUID();
	
	Schedule = CurrentObject.Schedule.Get();
	SetPresentationSchedule(ThisObject);
	
	MethodParameters = CommonUse.ValueToXMLString(CurrentObject.Parameters.Get());
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.Schedule = New ValueStorage(Schedule);
	CurrentObject.Parameters = New ValueStorage(CommonUse.ValueFromXMLString(MethodParameters));
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	ID = Object.Ref.UUID();
	
EndProcedure

#EndRegion

#Region FormManagementItemsEventsHandlers

&AtClient
Procedure SchedulePresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	LockFormDataForEdit();
	
	If ValueIsFilled(Object.Pattern) Then
		ShowMessageBox(, NStr("en='Schedule is set in the template for jobs created from templates.';ru='Для заданий на основе шаблонов, расписание задается в шаблоне.';vi='Để đặt trên cơ sở khuôn mẫu, lịch biểu được đặt trong khuôn mẫu.'"));
		Return;
	EndIf;
	
	If Schedule = Undefined Then
		EditSchedule = New JobSchedule;
	Else
		EditSchedule = Schedule;
	EndIf;
	
	Dialog = New ScheduledJobDialog(EditSchedule);
	OnCloseNotifyDescription = New NotifyDescription("ChangeSchedule", ThisObject);
	Dialog.Show(OnCloseNotifyDescription);
	
EndProcedure

&AtClient
Procedure SchedulePresentationForClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	LockFormDataForEdit();
	
	Schedule = Undefined;
	Modified = True;
	SetPresentationSchedule(ThisObject);
	
EndProcedure

#EndRegion

#Region ServiceProceduresAndFunctions

&AtClient
Procedure ChangeSchedule(NewSchedule, AdditionalParameters) Export
	
	If NewSchedule = Undefined Then
		Return;
	EndIf;
	
	Schedule = NewSchedule;
	Modified = True;
	SetPresentationSchedule(ThisObject);
	
	ShowUserNotification(NStr("en='Replanning';ru='Перепланирование';vi='Lập lại kế hoạch'"), , NStr("en='New schedule will be taken into account"
"when executing the next job';ru='Новое расписание будет учтено"
"при следующем выполнении задания';vi='Sẽ áp dụng lịch biểu mới"
"khi thực hiện nhiệm vụ lần tiếp theo'"));
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetPresentationSchedule(Val Form)
	
	Schedule = Form.Schedule;
	
	If Schedule <> Undefined Then
		Form.SchedulePresentation = String(Schedule);
	ElsIf ValueIsFilled(Form.Object.Pattern) Then
		Form.SchedulePresentation = NStr("en='<Specified in the template>';ru='<Задается в шаблоне>';vi='<Đặt vào khuôn mẫu>'");
	Else
		Form.SchedulePresentation = NStr("en='<Not specified>';ru='<Не задано>';vi='<Chưa đặt>'");
	EndIf;
	
EndProcedure

#EndRegion


