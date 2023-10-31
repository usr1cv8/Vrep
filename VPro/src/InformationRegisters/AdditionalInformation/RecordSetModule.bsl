
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventsHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If CommonUse.SubsystemExists("StandardSubsystems.ObjectVersioning") Then
		FilterItem = Filter.Find("Object");
		If FilterItem <> Undefined Then
			ObjectVersioningModule = CommonUse.CommonModule("ObjectVersioning");
			SetPrivilegedMode(True);
			ObjectVersioningModule.WriteObjectVersion(FilterItem.Value);
			SetPrivilegedMode(False);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("en='Invalid object call at client.';ru='Недопустимый вызов объекта на клиенте.';vi='Không thể gọi ra đối tượng trên Client.'");
#EndIf