#Region EventsHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FormParameters = New Structure;
	FormParameters.Insert("ShowAdditionalAttributes");
	OpenForm("Catalog.AdditionalAttributesAndInformationSets.ListForm",
		FormParameters,
		CommandExecuteParameters.Source,
		"AdditionalAttributes",
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
EndProcedure

#EndRegion