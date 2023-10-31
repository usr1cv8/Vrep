
#Region FormEventsHandlers

#EndRegion

#Region HeaderFormItemsEventsHandlers

&AtClient
Procedure IsReceiptFromOneCountryOnChange(Item)
	
	CommonUseClientServer.SetFormItemProperty(Items, "CountryOfOrigin", "Enabled", IsReceiptFromOneCountry);
	
	If Not IsReceiptFromOneCountry Then
		
		CountryOfOrigin = Undefined;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventsHandlers

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure OK(Command)
	
	ClosingParameters = New Structure;
	ClosingParameters.Insert("CCDNo", CCDNo);
	ClosingParameters.Insert("IsReceiptFromOneCountry", IsReceiptFromOneCountry);
	ClosingParameters.Insert("CountryOfOrigin", CountryOfOrigin);
	
	Close(ClosingParameters);
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

#EndRegion
