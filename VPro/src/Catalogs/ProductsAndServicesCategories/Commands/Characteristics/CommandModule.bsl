
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters) 
	FormParameters = New Structure("Filter", New Structure("Owner",CommandParameter));
	OpenForm("Catalog.ProductsAndServicesCharacteristics.ListForm", FormParameters, CommandExecuteParameters.Source,,CommandExecuteParameters.Window);
EndProcedure
