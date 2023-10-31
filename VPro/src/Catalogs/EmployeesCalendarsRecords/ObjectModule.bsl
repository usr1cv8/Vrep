#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventsHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		FillPropertyValues(ThisObject, FillingData);
	EndIf;
	
	AddByDefault();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If End < Begin Then
		CommonUseClientServer.MessageToUser(
		NStr("en='End date cannot be less than the start date.';ru='Дата окончания не может быть меньше даты начала.';vi='Ngày kết thúc không thể nhỏ hơn ngày bắt đầu.'"),
		ThisObject,
		"End",
		,
		Cancel);
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
		
	DataExchange.Recipients.AutoFill = False;
	DataExchange.Recipients.Clear();
	
	If DataExchange.Load Then
		Return;
	EndIf;
		
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

Procedure AddByDefault()
	
	If ValueIsFilled(Calendar) Then
		Return;
	EndIf;
	
	Calendar = SmallBusinessReUse.GetValueOfSetting("DefaultCalendar");
	
EndProcedure

#EndRegion

#EndIf