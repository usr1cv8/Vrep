#Region EventsHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FormParameters = New Structure;
	FormParameters.Insert("ShowAdditionalInformation");
	OpenForm("Catalog.AdditionalAttributesAndInformationSets.ListForm",
		FormParameters,
		CommandExecuteParameters.Source,
		"AdditionalInformation",
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
EndProcedure

#EndRegion