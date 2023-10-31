
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetupAvailableCalendars();
	
	List.Parameters.SetParameterValue("DefaultCalendar",
		SmallBusinessReUse.GetValueOfSetting("DefaultCalendar"));
	
	// Установим настройки формы для случая открытия в режиме выбора
	Items.List.ChoiceMode = Parameters.ChoiceMode;
	Items.List.MultipleChoice = ?(Parameters.CloseOnChoice = Undefined, False, Not Parameters.CloseOnChoice);
	If Parameters.ChoiceMode Then
		PurposeUseKey = PurposeUseKey + "PickupSelection";
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
	Else
		PurposeUseKey = PurposeUseKey + "List";
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Record_EmployeeCalendar" Then
		SetupAvailableCalendars();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormItemEventsHandlers

&AtClient
Procedure ListOnActivateRow(Item)
	
	If TypeOf(Items.List.CurrentRow) <> Type("DynamicListGroupRow")
		And Items.List.CurrentData <> Undefined Then
		
		Items.FormUseAsDefault.Enabled = Not Items.List.CurrentData.ItDefault;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure UseAsDefault(Command)
	
	If TypeOf(Items.List.CurrentRow) = Type("DynamicListGroupRow")
		Or Items.List.CurrentData = Undefined
		Or Items.List.CurrentData.ItDefault Then
		
		Return;
	EndIf;
	
	SetupDefaultCalendar(Items.List.CurrentData.Ref);
	Items.FormUseAsDefault.Enabled = Not Items.List.CurrentData.ItDefault;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure SetupDefaultCalendar(Val NewMainCalendar)
	
	SmallBusinessServer.SetUserSetting(NewMainCalendar, "DefaultCalendar");
	List.Parameters.SetParameterValue("DefaultCalendar", NewMainCalendar);
	
EndProcedure

&AtServer
Procedure SetupAvailableCalendars()
	
	If Not Users.InfobaseUserWithFullAccess() Or Parameters.OnlyOwn Then
		AvailableCalendars = Catalogs.EmployeesCalendars.AvailableEmployeeCalendars().UnloadColumn("Calendar");
		List.Parameters.SetParameterValue("AvailableCalendars", AvailableCalendars);
	EndIf;
	
EndProcedure

#EndRegion
