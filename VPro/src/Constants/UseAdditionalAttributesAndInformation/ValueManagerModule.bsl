
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var ValueChanged;

#EndRegion

#Region EventsHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	ValueChanged = Value <> Constants.UseAdditionalAttributesAndInformation.Get();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ValueChanged Then
		If CommonUse.SubsystemExists("StandardSubsystems.AccessManagement") Then
			AccessControlModule = CommonUse.CommonModule("AccessManagement");
			AccessControlModule.RefreshAllowedValuesOnChangeAccessKindsUsage();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("en='Invalid object call at client.';ru='Недопустимый вызов объекта на клиенте.';vi='Không thể gọi ra đối tượng trên Client.'");
#EndIf