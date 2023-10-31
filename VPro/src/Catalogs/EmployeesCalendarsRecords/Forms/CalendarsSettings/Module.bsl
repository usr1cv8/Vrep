
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If CommonUseClientServer.IsMobileClient() Then

		ThisForm.CommandBar.HorizontalAlign = ItemHorizontalLocation.Left;
		ThisForm.CommandBarLocation = FormCommandBarLabelLocation.Top;
		Items.FormOK.Picture = PictureLib.Done;
		
	EndIf;
	
	FillPropertyValues(ThisObject, Parameters.DisplaySettings);
	WorkingDayBeginning		= Date(1,1,1, Parameters.DisplaySettings.WorkingDayBeginning, 0,0);
	WorkingDayEnd	= Date(1,1,1, Parameters.DisplaySettings.WorkingDayEnd, 0,0);
	
	EventsCMClientServer.ЗаполнитьСписокВыбораВремени(Items.WorkingDayBeginning, 3600, '00010101000000', '00010101230000');
	EventsCMClientServer.ЗаполнитьСписокВыбораВремени(Items.WorkingDayEnd, 3600, '00010101000000', '00010101230000');
	
	// Нулевое время обозначает конец дня, поэтому поставим его последним элементом
	Items.WorkingDayEnd.ChoiceList.Move(0, Items.WorkingDayEnd.ChoiceList.Count()-1);
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure OK(Command)
	
	If Not Modified Then
		NotifyChoice(Undefined);
		Return;
	EndIf;
	
	If Not CheckСorrectness() Then
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("WorkingDayBeginning",		Hour(WorkingDayBeginning));
	Result.Insert("WorkingDayEnd",	Hour(WorkingDayEnd));
	Result.Insert("ShowCurrentDate",	ShowCurrentDate);
	
	NotifyChoice(Result);
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Function CheckСorrectness()
	
	FillindCorrect = True;
	
	If WorkingDayEnd < WorkingDayBeginning Then
		CommonUseClientServer.MessageToUser(
			NStr("en='Окончание дня не может быть меньше начала.';ru='Окончание дня не может быть меньше начала.';vi='Cuối ngày không thể ít hơn đầu ngày.'"),
			,
			"WorkingDayEnd"
		);
		FillindCorrect = False;
	EndIf;
	
	Return FillindCorrect;
	
EndFunction

#EndRegion
