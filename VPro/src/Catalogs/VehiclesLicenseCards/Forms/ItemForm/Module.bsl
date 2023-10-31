
#Region ServiceProceduresAndFunctions

&AtClient
Procedure GenerateDescription()
	
	Object.Description = NStr("en='Series ';ru='серия ';vi='sê-ri'") + Object.LicenseCardSeries + NStr("en=' # ';ru=' # ';vi=' # '") + Object.LicenseCardNumber + NStr("en=' dated ';ru=' от ';vi='ngày'") + Format(Object.LicenseCardsDateIssued, "DF=dd.MM.yyyy");
	
	If ValueIsFilled(Object.LicenseOwner) Then
		
		Object.Description = Object.Description + NStr("en='. Owner: ';ru='. Владелец: ';vi='. Chủ sở hữu:'") + Object.LicenseOwner;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormEventsHandlers

#EndRegion

#Region FormItemEventsHandlers

&AtClient
Procedure LicenseCardSeriesOnChange(Item)
	
	GenerateDescription();
	
EndProcedure

&AtClient
Procedure LicenseCardNumberOnChange(Item)
	
	GenerateDescription();
	
EndProcedure

&AtClient
Procedure LicenseCardsDateIssuedOnChange(Item)
	
	GenerateDescription();
	
EndProcedure

&AtClient
Procedure LicenseOwnerOnChange(Item)
	
	GenerateDescription();
	
EndProcedure

#EndRegion